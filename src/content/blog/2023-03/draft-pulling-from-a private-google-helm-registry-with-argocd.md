---
author: Scott Walker
pubDatetime: 2023-03-21T15:00:00Z
title: Deploy a helm chart from Google Artifact Registry with ArgoCd
postSlug: deploying-a-helm-chart-from-google-artifact-registry-with-argocd
featured: true
draft: false
tags:
  - GoogleCloudPlatform
  - ArgoCd
  - Helm
  - GoogleArtifactRegistry
ogImage: ""
description: How to deploy a helm chart from Google Artifact Registry with ArgoCd
---

[ArgoCd](https://argoproj.github.io/cd/) is a great open source tool that allows you to simply manage your resources. It also allows you to connect to private registries and pull helm charts. In this blog, we'll go over how to do this when your registry is Google Artifact Registry!

> Caveat - In order follow this, you should have a Kubernetes cluster installed with Google Kubernetes Engine as well as the GCloud CLI and Kubectl installed on your machine. It's also assumed that you have an understanding of helm.


## Ensuring we have a good setup

Before we get started with the good stuff of deploying our helm chart, there's some housekeeping that we have to go through. We need to ensure that we have all of the rights and service accounts setup so we're able to pull our helm chart.

Another presumption here is that you have your Google Cloud project setup and that you've activated billing. If you haven't done this, make sure you do before going forward.

With all that in place, let's get going!!

### Creating our artifact registry and pushing a chart

Firstly, we need to ensure that we can create our registry. All of GCP's functionalities are behind 'feature walls' for want of a better phrase. To enable this we can run:

``` 
gcloud services enable artifactregistry.googleapis.com
```

Once this has successfully ran, we can create our first repository.

```
gcloud artifacts repositories create my-first-helm-repo --location=europe-west4 --repository-format=DOCKER
```

`my-first-helm-repo` is the new name of our repository, our location is set to `europe-west4` which is Amsterdam and our format is `docker` which is what we need for the helm chart.

Now that the repo is in place, let's push our chart. Helm create gives us a nice sample chart that we can create directly from the cli.

```
helm create hello-world
```
```
helm package hello-world
```

After running these commands you should end up with a `.tgz` file named `hello-world-0.1.0.tgz`. We're now ready to push the package!

> I'm taking another presumption that your GCloud CLI is the one you created the project with, meaning you should already have the necessary permissions.


```
helm push hello-world-0.1.0.tgz oci://europe-west4-docker.pkg.dev/{my-project-name}/my-first-helm-repo
```

So here `hello-world-0.1.0.tgz` is the chart that we're pushing, `europe-west4` is the location we stated when creating the repo, `docker` is the repo type, `{my-project-name}` is whatever the name of your Google project is and `my-first-helm-repo- is the name of the repo we created.

All being well we should now have chart in our helm repo!

## Creating the service account


## Creating the ArgoCd repo and application

## Conclusion
