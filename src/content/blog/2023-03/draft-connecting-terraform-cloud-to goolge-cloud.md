---
author: Scott Walker
pubDatetime: 2023-03-22T17:00:00Z
title: Connect to Google Cloud using Terraform Cloud and Github Actions
postSlug: connecting-terraform-cloud-to-google-cloud-platform-and-github-actions
featured: true
draft: true
tags:
  - GoogleCloudPlatform
  - Terraform
  - TerraformCloud
  - Github Actions
ogImage: ""
description: How to connect to Google Cloud using Terraform Cloud as state with Github Actions
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

### Terraform Api Key

## Github Actions and our Terraform file