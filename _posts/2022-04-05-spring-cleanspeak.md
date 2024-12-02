---
layout: blog-post
title: "Spring Framework CVE: How it affects CleanSpeak (TLDR: It doesn't)"
author: Dan Moore
author_image: "/images/blog-archive/mooreds.jpg"
excerpt_separator: "<!--more-->"
categories:
- News
tags:
- Updates
- CleanSpeak
image: blog/spring4shell/spring-update-cleanspeak.png
---

The recent announcement of [CVE-2022-22965](https://nvd.nist.gov/vuln/detail/CVE-2022-22965), where "a Spring MVC or Spring WebFlux application running on JDK 9+ may be vulnerable to remote code execution (RCE) via data binding," has some folks asking if CleanSpeak is affected. This CVE is also known as the "Spring4Shell" vulnerability.

CleanSpeak is not affected by this vulnerability in Spring. CleanSpeak uses a different MVC framework, [Prime](https://github.com/prime-framework/prime-mvc), so there is no way that any CleanSpeak applications could be compromised. 

<!--more-->

Spring is a popular application framework and is used in many Java projects, both open source and commercial.

When a CVE like this comes out, it makes sense to check all of your applications to see if they are affected. Security is important to us and we understand why customers and users would reach out about this.

In conclusion, CleanSpeak is *not affected by the Spring vulnerability*.

To learn more about the CVE, you can:

* visit the [CVE description](https://nvd.nist.gov/vuln/detail/CVE-2022-22965)
* visit the [VMWare CVE description](https://tanzu.vmware.com/security/cve-2022-22965)
* review a [detailed report about the vulnerability](https://spring.io/blog-archive/2022/03/31/spring-framework-rce-early-announcement)
* participate in the [HackerNews discussion](https://news.ycombinator.com/item?id=30871128)

## A bit more about security and CleanSpeak

Beyond this specific vulnerability, we want to assure readers that CleanSpeak takes security very seriously. 

This commitment includes, but is not limited to:

* a responsible disclosure program
* regular penetration tests
* security disclosures in our extensive [release notes](/docs/3.x/tech/release-notes/)

