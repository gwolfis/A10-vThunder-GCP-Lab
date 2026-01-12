# Getting started

This guide explains the prerequisites and one time setup you need to run the A10 vThunder ADC lab on Google Cloud with Terraform.

## What you need on your workstation

1. Terraform installed  
   Recommended is a recent Terraform 1.x release.

2. Git installed  
   You will clone this repository and run Terraform from your local working directory.

3. Google Cloud CLI installed  
   You can do everything in the Google Cloud Console, but `gcloud` is handy for validation and scripting.

## Google Cloud prerequisites

### 1. An existing Google Cloud project

1. Make sure you already have a Google Cloud project and that Billing is enabled for it.
2. Note the Project ID because you will use it in Terraform variables and in commands.

### 2. Enable required APIs in the project

Enable the APIs required for provisioning Compute Engine resources and managing IAM.

1. In the Google Cloud Console, go to APIs and Services then Library.
2. Enable at least these APIs
   1. Compute Engine API
   2. Cloud Resource Manager API
   3. Identity and Access Management API
   4. Service Usage API


Official reference on enabling services is here: 
https://docs.cloud.google.com/service-usage/docs/enable-disable



### 3. Create a service account named `terraform-deployer`
This lab expects a dedicated service account in your project named terraform-deployer.

Console steps:

1. Go to IAM and Admin then Service Accounts.

2. Click Create service account.

3. Set the service account name to `terraform-deployer`.

4. Finish creation, you can assign roles in the next step.

Official Google Cloud guide for creating service accounts is here:
https://docs.cloud.google.com/iam/docs/service-accounts-create


### 4. Grant IAM roles to `terraform-deployer`
Grant the service account the same roles shown in the screenshot you attached.

Assign these roles at the project level:

| Console role name | IAM role id |
|---|---|
| Compute Admin | `roles/compute.admin` |
| Compute Network Admin | `roles/compute.networkAdmin` |
| Project IAM Admin | `roles/resourcemanager.projectIamAdmin` |
| Service Account Admin | `roles/iam.serviceAccountAdmin` |
| Service Account User | `roles/iam.serviceAccountUser` |
| Storage Admin | `roles/storage.admin` |


Console steps:

1. Go to IAM and Admin then IAM.

2. Click Grant Access.

3. Principal is the service account terraform-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com.

4. Add the roles listed above and save.

Google Cloud reference for managing access and granting roles is here: 
https://docs.cloud.google.com/iam/docs/manage-access-service-accounts

### 5. Create a JSON key and download credentials
Terraform will authenticate using a JSON key for the terraform-deployer service account.

Console steps:

1. Go to IAM and Admin then Service Accounts.

2. Open `terraform-deployer`.

3. Go to the Keys tab.

4. Click Add key then Create new key.

5. Choose JSON and create the key.

A JSON file will download to your machine.

Official Google Cloud guide for creating service account keys is here. 
Google Cloud Documentation

### 6. Save the credentials as `terraform-sa.json` where `main.tf` expects it
This repository uses a local credentials file named terraform-sa.json as referenced in main.tf.

Rename the downloaded key file to terraform-sa.json.

Place it in the exact path that the Google provider configuration in main.tf references.
Common patterns you might see are a file in the repo root next to main.tf or a module relative path.

**Security note, never commit this file to git. Add this line to your .gitignore:**

``` gitignore

terraform-sa.json
```
If you prefer, Google also documents using the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to a service account JSON file, but for this lab you should follow the main.tf approach unless you intentionally change it. 


### 7. Quick validation
If you want to sanity check the key and permissions before running Terraform, you can authenticate with `gcloud`:

``` bash

gcloud auth activate-service-account --key-file=terraform-sa.json
gcloud config set project YOUR_PROJECT_ID
gcloud compute regions list
```

If the last command returns regions, authentication is working and the service account can call Compute Engine APIs.

## Next
Once the prerequisites above are complete you can continue with the deployment instructions in the next document of the guide.


Continue with the next step:

* [gcp-infra](gcp-infra.md)

---
**Next:** [gcp-infra](gcp-infra.md)
**Previous:** [index](index.md)