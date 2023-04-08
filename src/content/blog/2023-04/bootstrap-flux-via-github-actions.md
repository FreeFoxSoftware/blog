---
author: Scott Walker
pubDatetime: 2023-04-09T23:25:00Z
title: How to Bootstrap Flux via a Github Action
postSlug: bootstrap-flux-via-github-action
featured: false
draft: false
tags:
  - Flux
  - Github Actions
ogImage: ""
description: Flux is a fantastic tool for continuous delivery. Here I'll show you how we can install it in a GitOps way
---

[Flux](https://fluxcd.io/) is a continuous delivery solution built for Kubernetes that allows you to work in true `GitOps` methodology. It's installation is exceedingly easy with a single command line execution and, as it's a one off process, we could just leave it there and be happy. Then again, that's not very 'GitOps' so we're going to go through how to install flux via a Github Action.

## Generating the SSH Keys

Before we dive into the Github side of things, there's a little bit of setup. We need to be able to authenticate with our Github Account whilst running inside a Github Action (Inception like). This is because Flux does a commit to your configured branch when you bootstrap it and if you don't have write Access to your Github account when running your pipeline then Flux won't be able to install. We're going to do this using an `SSH` key. You can generate an SSH key using the `ssh-keygen` command on either Windows or Linux. Just open up the terminal and run:

``` shell
ssh-keygen
```

When this command has executed it will ask you to name the file and it's location. The name is arbitrary as is it's location but make sure you know where it's at! You'll also be given the option to give it a passphrase but it's not necessary for our use case. To make this simple to follow, we're going to name the file `flux`.

Once you've chosen a file name there will be two new files created. The first will be named `flux` (this is our `private key`) with the second being `flux.pub` (our `public key`). Both are important as the `.pub` file will be stored to your Github Repository as a `deploy key` whilst the private key will be stored directly in our source code.

> In our example, we'll be storing this unencrypted for demonstration purposes. In a production environment this should be encrypted via a tool like [Mozilla Sops](https://github.com/mozilla/sops).

We'll start with handling the private key. This is easy enough as we can just take the file and commit it directly to the Git Repository. For the public key, we need to copy the value and head over to your repository on [Github](github.com). On your repository page, click `settings` and then on the left pane under `security` there is an option for `Deploy Keys`. Click Add key and paste in the contents of your `.pub` file. Before you save this, make sure you click the checkbox that allows write access, otherwise Flux won't have the permissions to commit itself to Git!

<figure>
  <img
    src="/assets/flux-install-deploy-keys.png"
    alt=""
  />
  <figcaption>
    Deploy keys location on Github
  </figcaption>
</figure>


## Adding it to our Github Action

Now that that is in place, we just need to add a step to our Github Action. I've ommitted the rest of the yaml for brevity as most of it is unnecessary.

```yaml
    - name: Install Flux
      run: |
        curl -s https://fluxcd.io/install.sh | sudo bash

        flux bootstrap git \
          --url=ssh://git@github.com/{github-organisation-name}/{github-repo-name}.git \
          --branch=main \
          --path=clusters/my-cluster-name \
          --private-key-file=./flux.sshkey.enc \
          --silent=true
```

Let's explain this command quickly. The `url` and `branch` command are used to specify what repository we're committing to (This should match the repository where you put your deploy key earlier) and the branch that it will commit to. Normally this will be your `main` or `master` branch. 

The `path` argument will be where Flux adds its files. This path doesn't need to exist as Flux will create it if it isn't already there. 

`private-key-file` is the location of our private key within our repository. In the situation above, I've placed it in the root of the repository. If yours is elsewhere, then change the value to that location.

`silent` will skip the prompt asking if you want to give the key access to your repository. This prompt is useless to us as we're running this in a pipeline with no user input necessary and we've already given our key access.

All going well, running this pipeline should successfully install Flux. The cool thing about the `flux bootstrap` command is that it's `idempotent` so we don't need any random if statements in our pipeline. If it is already there, then it won't make any changes!

## Conclusion

That's it!

We've covered a truly `GitOps` way of installing Flux into our cluster. You could argue that this way a little overkill considering you only need to run the command once but I'd much rather have this is an automated pipeline over a random document or readme.

Thanks for reading.✌🏻
