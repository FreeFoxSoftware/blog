---
author: Scott Walker
pubDatetime: 2023-03-22T17:00:00Z
title: Deploy a helm chart from Google Artifact Registry with ArgoCd
postSlug: deploying-a-helm-chart-from-google-artifact-registry-with-argocd
featured: false
draft: false
tags:
  - GoogleCloudPlatform
  - ArgoCd
  - Helm
  - GoogleArtifactRegistry
ogImage: ""
description: Helm and Argo are two powerful tools to help manage your deployments. Here I'll show you how they can work together along with a Google Artifact Registry
---

[ArgoCd](https://argoproj.github.io/cd/) is a great open source tool that allows you to simply manage your resources. It also allows you to connect to private registries and pull helm charts. In this blog, we'll go over how to do this when your registy is Google Artifact Registry!

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

> I'm taking another presumption that your GCloud CLI is the one you created the project with, meaning you should already have the necessary permissions. I'll cover pushing charts from GitHub in another blog.


```
helm push hello-world-0.1.0.tgz oci://europe-west4-docker.pkg.dev/{my-project-name}/my-first-helm-repo
```

If you get a `403` error, you can login to the registry with the following command

linux:
```
gcloud auth print-access-token | helm registry login -u oauth2accesstoken --password-stdin https://europe-west4-docker.pkg.dev
```

Windows: [link](https://cloud.google.com/artifact-registry/docs/helm/store-helm-charts#windows)

You should now be logged in.

So here `hello-world-0.1.0.tgz` is the chart that we're pushing, `europe-west4` is the location we stated when creating the repo, `docker` is the repo type, `{my-project-name}` is whatever the name of your Google project is and `my-first-helm-repo- is the name of the repo we created.

All being well we should now have chart in our helm repo!


## Creating the service account

To be able to pull our chart from helm chart, Argo needs service account credentials with the ability to download artifacts. So let's first create a service account!

```
gcloud iam service-accounts create helm-chart-retriever

```

Once this has been created, we need to give the service account the ability to pull from the registry. For this we can add the `registry reader` role.

```
gcloud projects add-iam-policy-binding {my-project-name} --member="serviceAccount:helm-chart-retriever@{my-project-name}.iam.gserviceaccount.com" --role="roles/artifactregistry.reader"
```

If this ran successfully, you should have received a list of your service accounts back from the cli.

## Download the credential file

Ok, we're around halfway there and we now need to create our own key. The easiest way to do this is via the GUI.

1. Go to your Google Cloud Console
2. On the navigation pane, click on `IAM`
3. On the navigation pane, click on `Service Accounts`
4. Click the service account with the name `helm-chart-retriever` (If you gave it a different name, click that one)
5. On the tabs, click the option of `keys`
6. Create a new key and keep it as a `json` file

Now that the file has downloaded copy the contents and base64 encode them. Keep the base64 encoded value safe. You'll need it in the next step!

## Creating the ArgoCd repo and application

Now we're onto the final part of the show! Having Argo pull from helm repo and deploy the chart!

We'll start by creating a secret with a set of values that allows Argo to understand that this is an external repository it should be aware of.

```yaml

apiVersion: v1
kind: Secret
metadata:
  name: helm-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository  # This is what tells Argo that it's a repository
stringData:
  type: helm
  enableOci: "true"
  url: europe-west4-docker.pkg.dev
  name: test-helm
  username: "_json_key_base64"
  password: "{base-64-credential-from-service-account}" # The base 64 encoded string from earlier
```

Couple of things to take note of here. The username can be either `_json_key` which is a non encoded service account credential or the `_json_key_base64` which is what we're using here. I prefer the base 64 version as it makes it easier to inject as a secret from a pipeline etc. Also, if you're Argo namespace is not `argocd` then make sure to change that to whatever your value is.

Now that we've got the repository in place, let's create our Argo application!

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-world
  namespace: argocd
spec:
  destination:
    namespace: hello-world
    server: https://kubernetes.default.svc
  project: default
  source:
    chart: {my-project-name}/my-first-helm-repo/hello-world
    repoURL: europe-west4-docker.pkg.dev
    targetRevision: "0.1.0"
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Run `kubectl apply -f ` to apply these new files and your result should look something like this!

<figure>
  <img
    src="/assets/hello-world-deployed.png"
    alt=""
  />
  <figcaption>
    Our deployed application in Argo!
  </figcaption>
</figure>

## Conclusion

In this, we went through and created an application in ArgoCd that pulls it's information from a Helm chart stored in our Google Artifact Registry!

It was a bit of a longer one to read through but I hope it was helpful. If you're having issues then feel free to message me on LinkedIn.

Thanks for reading!!
