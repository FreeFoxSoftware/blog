---
author: Scott Walker
pubDatetime: 2023-03-21T15:00:00Z
title: How to solve DNS Zone validation errors in GCP
postSlug: solving-dns-zone-validation-in-gcp
featured: true
draft: false
tags:
  - GoogleCloudPlatform
  - DNS
ogImage: ""
description: Solving a DNS validation issue ('Error creating ManagedZone') within the Google Cloud Platform
---

A couple of days ago I was creating my DNS zone via Terraform in Google Cloud Platform for `scottwalker.dev` and I ran into this error:

`Error creating ManagedZone: googleapi: Error 400: Please verify ownership of the 'scottwalker.dev.' domain (or a parent) at http://www.google.com/webmasters/verification/ and try again, verifyManagedZoneDnsNameOwnership`.

Clicking the link confirmed that my account was verified yet I was still getting the errors.

## TLDR

I was receiving the error `Error creating ManagedZone: googleapi: Error 400: Please verify ownership of the 'scottwalker.dev.' domain (or a parent) at http://www.google.com/webmasters/verification/ and try again, verifyManagedZoneDnsNameOwnership`. Everything was already verified according to the `webmasters/verification` but it appears that it was only verified for the email with which I registered. You can also add other email addresses that can be 'validated'. Adding the email address for the service account of Terraform (The service account actually creating the zone) solved this.

## The Problem

Whenever I tried creating my DNS Zone via Terraform I was met with the above error. Strangely enough, my domain was already verified and I was still meeting this issue. I could create the zone manually and have no issues but the Terraform issue persisted.

## The Solution (and the steps in getting there)

Even though the `webmasters/verification` said that everything was fine and valid, there were some recommended steps that we could take to validate it. Google's manner of doing so was to add a `TXT record` at the provider where I bought my domain. In my case, Google Domains.

### Adding a TXT record
> Warning - This first step for me didn't solve the issue, but it could for you. It's written as it's Google's recommendation.

I won't go into the specifics on the Google Domains workflow as the specifics will be different per registra but the overall flow should be similar.

- Ensure that you're adding the record to the correct place. E.G. if you're using `Custom Name Servers` then add the record to wherever that is hosted. If you're not using Custom Name Servers then continue using the default name servers. 
- Add a text record with the provided data from `webmasters/verification`. Leave the host name black if you want to verify your root domain.
- Return to the `webmasters/verification` and click the 'validate' button.

All going well, this could solve your issue!!

### Adding another Google email

What I've found  is that when Webmasters tells you that it is valid, it's only half of the story. My understanding is that this is verified on the user currently using it.

In my case, that was the personal email address that I used to setup my domain. But it wasn't that account that was attempting to create the zone, it was the Terraform service account. So, on the bottom of the validation page there is also an `add an owner` button. Here, add the email address of the service account attempting to create the zone E.G. `terraform@{my-project-name}.iam.gserviceaccount.com`

After this is added, try and create it again and hopefully you have success!

## Conclusion

That's it!

We've covered a couple of methods to solve the 'Error creating ManagedZone' error. Hopefully one of these solutions will help you fix this issue

Thanks for reading.✌🏻
