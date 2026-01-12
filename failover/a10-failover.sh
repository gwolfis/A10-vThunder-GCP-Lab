#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "$(date -Is) $*"
}

die() {
  log "ERROR: $*"
  exit 1
}

CONFIG_FILE="/etc/a10-failover/env"
if [[ -f "${CONFIG_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"
  set +a
else
  log "WARN: ${CONFIG_FILE} not found, relying on environment variables"
fi

PROJECT="$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/project-id || true)"
[[ -n "${PROJECT}" ]] || die "Could not determine project ID from metadata"
gcloud config set project "${PROJECT}" >/dev/null 2>&1 || die "Failed to set gcloud project to ${PROJECT}"

: "${REGION:?missing REGION}"
: "${PRIMARY_TI:?missing PRIMARY_TI}"
: "${PRIMARY_ZONE:?missing PRIMARY_ZONE}"
: "${SECONDARY_TI:?missing SECONDARY_TI}"
: "${SECONDARY_ZONE:?missing SECONDARY_ZONE}"
: "${FW_FILTER:?missing FW_FILTER}"

HEALTH_POLICY="$(echo "${HEALTH_POLICY:-ANY}" | tr '[:lower:]' '[:upper:]')"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-3}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"
LOOP_INTERVAL_SECONDS="${LOOP_INTERVAL_SECONDS:-30}"
COOLDOWN_AFTER_FAILOVER_SECONDS="${COOLDOWN_AFTER_FAILOVER_SECONDS:-180}"

OPENSSL_TIMEOUT_SECONDS="${OPENSSL_TIMEOUT_SECONDS:-6}"
HEALTHCHECK_TOOL="$(echo "${HEALTHCHECK_TOOL:-OPENSSL}" | tr '[:lower:]' '[:upper:]')"

discover_vips() {
  local ips out
  ips="$(gcloud compute forwarding-rules list \
    --regions="${REGION}" \
    --filter="${FW_FILTER}" \
    --format='value(IPAddress)' 2>/dev/null || true)"

  if [[ -z "${ips}" ]]; then
    echo ""
    return 0
  fi

  out=""
  while read -r ip; do
    [[ -z "${ip}" ]] && continue
    out="${out} https://${ip}"
  done <<< "${ips}"

  echo "${out# }"
}

get_vips_array() {
  local vips
  vips="${VIPS_TO_CHECK:-}"
  if [[ -z "${vips}" ]]; then
    vips="$(discover_vips)"
  fi
  read -r -a VIPS_ARR <<< "${vips}"
  printf '%s\n' "${VIPS_ARR[@]}"
}

parse_host_port() {
  local vip="$1"
  local hostport

  hostport="${vip#https://}"
  hostport="${hostport#http://}"
  hostport="${hostport%%/*}"

  local host port
  host="${hostport}"
  port="443"

  if [[ "${hostport}" == *:* ]]; then
    host="${hostport%%:*}"
    port="${hostport##*:}"
  fi

  echo "${host} ${port}"
}

openssl_check_tls12() {
  command -v openssl >/dev/null 2>&1 || die "openssl not found, install with apt-get install openssl"

  local vip="$1"
  read -r host port < <(parse_host_port "${vip}")

  local out rc
  if command -v timeout >/dev/null 2>&1; then
    out="$(timeout "${OPENSSL_TIMEOUT_SECONDS}" \
      openssl s_client \
        -connect "${host}:${port}" \
        -servername "${host}" \
        -tls1_2 \
        -legacy_renegotiation \
        -brief < /dev/null 2>&1 || true)"
    rc=0
  else
    out="$(openssl s_client \
        -connect "${host}:${port}" \
        -servername "${host}" \
        -tls1_2 \
        -legacy_renegotiation \
        -brief < /dev/null 2>&1 || true)"
    rc=0
  fi

  if grep -qiE "handshake failure|alert|no peer certificate|connect:errno|connection refused" <<< "${out}"; then
    return 1
  fi

  if grep -qiE "Protocol[[:space:]]*version:[[:space:]]*TLSv1\\.2|Protocol[[:space:]]*:[[:space:]]*TLSv1\\.2" <<< "${out}" \
    && grep -qiE "Ciphersuite:|Cipher[[:space:]]*is|Cipher[[:space:]]*:" <<< "${out}"; then
    return 0
  fi

  return 1
}


tcp_check_443() {
  local vip="$1"
  read -r host port < <(parse_host_port "${vip}")

  if command -v timeout >/dev/null 2>&1; then
    timeout 3 bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" >/dev/null 2>&1
  else
    bash -c "cat < /dev/null > /dev/tcp/${host}/${port}" >/dev/null 2>&1
  fi
}

vip_check() {
  local vip="$1"

  if [[ "${HEALTHCHECK_TOOL}" == "OPENSSL" ]]; then
    openssl_check_tls12 "${vip}"
    return $?
  fi

  if [[ "${HEALTHCHECK_TOOL}" == "TCP" ]]; then
    tcp_check_443 "${vip}"
    return $?
  fi

  die "Unknown HEALTHCHECK_TOOL '${HEALTHCHECK_TOOL}', expected OPENSSL or TCP"
}

health_check() {
  mapfile -t VIPS_ARR < <(get_vips_array)

  if [[ "${#VIPS_ARR[@]}" -eq 0 ]]; then
    log "No VIPs found for health checks, check FW_FILTER and labels"
    return 0
  fi

  log "Running health checks (policy=${HEALTH_POLICY}, tool=${HEALTHCHECK_TOOL})"

  if [[ "${HEALTH_POLICY}" == "ANY" ]]; then
    for vip in "${VIPS_ARR[@]}"; do
      log "Checking VIP ${vip}"
      for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        if vip_check "${vip}"; then
          log "OK attempt ${i}"
          log "At least one VIP healthy, no failover"
          return 1
        fi
        log "FAIL attempt ${i}"
        sleep "${SLEEP_SECONDS}"
      done
    done
    log "All VIPs failed health checks, failover needed"
    return 0
  fi

  if [[ "${HEALTH_POLICY}" == "ALL" ]]; then
    local all_ok=1
    for vip in "${VIPS_ARR[@]}"; do
      log "Checking VIP ${vip}"
      local ok=0
      for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        if vip_check "${vip}"; then
          log "OK attempt ${i}"
          ok=1
          break
        fi
        log "FAIL attempt ${i}"
        sleep "${SLEEP_SECONDS}"
      done
      if [[ "${ok}" -eq 0 ]]; then
        all_ok=0
        break
      fi
    done

    if [[ "${all_ok}" -eq 1 ]]; then
      log "All VIPs healthy, no failover"
      return 1
    fi

    log "One or more VIPs failed health checks, failover needed"
    return 0
  fi

  log "Unknown HEALTH_POLICY '${HEALTH_POLICY}', expected ANY or ALL"
  return 1
}

perform_failover() {
  log "Starting failover"

  local rules
  rules="$(gcloud compute forwarding-rules list \
    --regions="${REGION}" \
    --filter="${FW_FILTER}" \
    --format='value(name)' 2>/dev/null || true)"

  if [[ -z "${rules}" ]]; then
    log "No forwarding rules matched filter '${FW_FILTER}', nothing to do"
    return 0
  fi

  log "Matched forwarding rules: ${rules}"

  local first_rule first_target to_ti to_zone
  first_rule="$(echo "${rules}" | head -n1)"
  first_target="$(gcloud compute forwarding-rules describe "${first_rule}" \
    --region="${REGION}" \
    --format='value(target)' 2>/dev/null || true)"

  if [[ -z "${first_target}" ]]; then
    log "Could not determine current target for ${first_rule}"
    return 1
  fi

  if [[ "${first_target}" == *"/targetInstances/${PRIMARY_TI}" ]]; then
    log "Active side PRIMARY (${PRIMARY_TI}), switching to SECONDARY (${SECONDARY_TI})"
    to_ti="${SECONDARY_TI}"
    to_zone="${SECONDARY_ZONE}"
  elif [[ "${first_target}" == *"/targetInstances/${SECONDARY_TI}" ]]; then
    log "Active side SECONDARY (${SECONDARY_TI}), switching to PRIMARY (${PRIMARY_TI})"
    to_ti="${PRIMARY_TI}"
    to_zone="${PRIMARY_ZONE}"
  else
    log "Current target does not match PRIMARY or SECONDARY, target=${first_target}"
    return 1
  fi

  for rule in ${rules}; do
    local current_target
    current_target="$(gcloud compute forwarding-rules describe "${rule}" \
      --region="${REGION}" \
      --format='value(target)' 2>/dev/null || true)"

    log "Rule ${rule} current target ${current_target}"

    if [[ "${current_target}" == *"/targetInstances/${to_ti}" ]]; then
      log "Rule ${rule} already on target ${to_ti}, skipping"
      continue
    fi

    log "Switching rule ${rule} to ${to_ti} in ${to_zone}"
    gcloud compute forwarding-rules set-target "${rule}" \
      --region="${REGION}" \
      --target-instance="${to_ti}" \
      --target-instance-zone="${to_zone}" >/dev/null 2>&1

    log "Rule ${rule} switched"
  done

  log "Failover done"
}

log "A10 failover watcher starting, project=${PROJECT}, region=${REGION}, filter='${FW_FILTER}'"
log "Primary=${PRIMARY_TI} ${PRIMARY_ZONE}, Secondary=${SECONDARY_TI} ${SECONDARY_ZONE}"
log "Healthcheck tool=${HEALTHCHECK_TOOL}, openssl timeout=${OPENSSL_TIMEOUT_SECONDS}s"

while true; do
  log "===== Healthcheck cycle ====="
  if health_check; then
    perform_failover
    log "Cooldown ${COOLDOWN_AFTER_FAILOVER_SECONDS}s after failover"
    sleep "${COOLDOWN_AFTER_FAILOVER_SECONDS}"
  else
    sleep "${LOOP_INTERVAL_SECONDS}"
  fi
done
