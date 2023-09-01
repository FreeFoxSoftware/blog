---
author: Scott Walker
pubDatetime: 2023-03-30T20:00:00Z
title: Connect to Google Cloud using Terraform Cloud and Github Actions
postSlug: connecting-terraform-cloud-to-google-cloud-platform-and-github-actions
featured: false
draft: false
tags:
  - GoogleCloudPlatform
  - Terraform
  - TerraformCloud
  - Github Actions
ogImage: ""
description: Terraform Cloud is a hosted manner of storing your Terraform state. Let's get this connected to Google Cloud via Github Actions
---  

Terraform is an open source tool that allows you to create resources for any of the major cloud platforms (as well as a few other ones). One of the key points of Terraform is its `state` file which is a `json` format file which represents the current state of your infrastructure. There are a few ways to store and manage this file but we're going to look into `Terraform Cloud`.


> Caveat - In order follow this, there is a presumption that you already have a Google Cloud account and a service account that Terraform can use.


## Getting the service account key

For Terraform to be able to connect to Google Cloud it needs a set of credentials, these credentials come in the form of a service account. It could be possible by the time you're reading this that you can connect using an identity rather than a service account but, as far as I can tell, this is not possible at the current time. So for now, we're going to make use of a service account key.

1. Go to your Google Cloud Console
2. On the navigation pane, click on `IAM`
3. On the navigation pane, click on `Service Accounts`
4. Click the service account with the name `helm-chart-retriever` (If you gave it a different name, click that one)
5. On the tabs, click the option of `keys`
6. Create a new key and keep it as a `json` file
7. Minify this file. I use a tool like [Json Formatter](https://jsonformatter.org/json-minify) but there are other options.

Keep this minified json safe we're going to need it later :-)

## Creating your Terraform Cloud Account

Here is where we're going to Terraform account. There will be a few steps in this that we need to setup and store some values for later. It's easier to do this now rather than going back and forth between your Terraform file and Github Actions.

### Organisation and Project

When signing up for Terraform Cloud you'll be prompted to create an `organisation`. This can be a company name, your name or any arbitrary value. The name of the organiastion will be used in your `main.tf` file as a part of your `provider` information. 

Next up we want to create a `workspace`. A workspace is a way of separating Terraform managed infrastructure within the same organisation. As an example, for an Ecommerce application, you may have a microservice for ordering and one for marketing. You could create separate workspace that manages each of the microservices. Again, the name for this doesn't really matter but we want to keep it for later as again we'll be using it in the `provider` segment of our `main.tf` file. The important thing to note is that for this tutorial, you want to choose the `Api Key` option when configuring the workspace.

### Terraform Variables

We need to setup a Terraform workspace `variable` that will be used by Terraform Cloud for connecting to GCP. Remember the minified json from earlier? You need that now.

Go to Terraform Cloud and open up your newly created workspace. On the navigation pane on the left hand side there should be an option for `variables`. Navigate to this page and you'll be able to add a new variable. When adding a variable you'll be confronted with two options, `Terraform Variable` or `Environment Variable`. The difference being that environment variables are used by the Terraform runtime whilst Terraform variables should also be declared in your Terraform file. When applying the state, Terraform will use the argument provided in the Terraform variable section to the Terraform runner. We'll be using the `Terraform Variable` and our key will be `gcp-credentials` with our value being the minified json. Make sure to declare it as `sensitive` so that it won't be showed again in the UI.

### Terraform Api Key

This is the last time for this blog we'll be acively in Terraform Cloud so this part is nearly complete! The last part is allowing out Github Actions pipeline to connect to Terraform Cloud and we'll do that using an `API token`. Terraform Cloud has two types of API token, a `user token` and an `organisation token` with an organisation token having the rights to manage teams and workspaces but crucially does not have the ability to `apply` and configuration. For this reason we'll be choosing the `user token`.

To create a user token you need to go to the `user settings` (under your profile image) and then choose `tokens`. Here you can create an API token. Again, the name doesn't matter but it should be easy to understand from the description what is using it. For example, the name of the repo connecting to it. 

## Github Actions and our Terraform file


We're now in the final stretch and are very close to deploying to Google via Terraform Cloud. We now just need to build our pipeline and make some changes to our `main.tf` file. Let's do this now!

```terraform
variable "gcp-credentials" {
  type        = string
  sensitive   = true
  description = "Google Cloud service account credentials"
}

terraform {
  cloud {
    organization = "your terraform organisation"

    workspaces {
      name = "your terraform workspace"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = var.gcp-credentials
  project     = "Your google project id"
  region      = "Your google region"
  zone        = "Your google zone"
}

```

First of all, note the name of the variable. This name matches the `key` that we used when creating the Terraform Cloud variable. THe other things to mention is that we need to replace the organisation and workspace with the ones that you created in Terraform Cloud.


Now the Github Action!!!

> Note, the jobs, build and other non necessary things have been omitted for the sake of brevity.

```yaml
  - uses: hashicorp/setup-terraform@v2
    with:
      cli_config_credentials_token: ${{ secrets.TERRAFORM_API_KEY }}

  - name: Terraform fmt
    id: fmt
    run: terraform fmt -check


  - name: Terraform Init
    id: init
    run: terraform init


  - name: Terraform Validate
    id: validate
    run: terraform validate -no-color


  - name: Terraform Plan
    id: plan
    run: |
      terraform plan -no-color

  - name: Terraform Apply
    id: apply
    run: | 
      terraform apply -auto-approve -input=false

```

Most of this is pretty self explanatory if you've seen Terraform before. We go through and check that it's formatted correctly, initialise by installing all necessary tooling, validate to make sure that the files make syntactic sense and finally plan and apply. The only thing we want to pay attention to our the `setup-terraform@v2` command. As a value for the `cli_config_credentials_token` command, I pass in an API token but in the form of a `GitHub secret`. This API token is the same token that we created earlier as a part of the Terraform Cloud setup. You don't have to make it a GitHub secret but its good practise to not have your secrets checked into code. Now, run your pipeline and you should be good!

## Conclusion

That's it! We've went through all of the necessary steps to deploy something to Google Cloud using Terraform whilst using Terraform Cloud to handle our state. I hope it has helped you in some way and gives you a start in automating your deployment processes and well as a simple manner of handling your state files.

Thanks for reading.✌🏻