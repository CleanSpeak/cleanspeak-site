---
layout: blog-post
title: "log4j CVE: How it affects CleanSpeak (TLDR: It doesn't)"
author: Dan Moore
author_image: "/images/blog/mooreds.jpg"
excerpt_separator: "<!--more-->"
categories:
- CleanSpeak
- News
tags:
- Updates
- CleanSpeak
image: blog/log4j-header.jpg
---

The recent announcement of [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228), which allows for "arbitrary code loaded from LDAP servers when message lookup substitution is enabled" through a vulnerability in log4J has many people double checking the dependencies of their Java applications.

CleanSpeak is not affected by this vulnerability in log4j. CleanSpeak uses a different logging framework, [logback](http://logback.qos.ch/), so there is no way that any CleanSpeak applications could be compromised. 

<!--more-->

log4j is a popular logging framework and is used in many Java projects, both open source and commercial. When a CVE like this comes out, it makes sense to check all of your applications for the issue. Security is important to us and we understand why customers and users would reach out about this.

In conclusion, CleanSpeak is *not affected by the log4j vulnerability*.

To learn more about the CVE, you can:

* visit the [NIST CVE description](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
* a [detailed report about the vulnerability](https://www.lunasec.io/docs/blog/log4j-zero-day/)
* the [HackerNews discussion](https://news.ycombinator.com/item?id=29504755)
* [a message from the logback maintainers about this issue](http://mailman.qos.ch/pipermail/announce/2021/000163.html)

## What about Elasticsearch

ElasticSearch is used by CleanSpeak installations. However, in general the ElasticSearch service is not publicly accessible, if [following the recommended security guidance](/docs/3.x/tech/installation-guide/securing).

Per the [ElasticSearch documentation](https://discuss.elastic.co/t/apache-log4j2-remote-code-execution-rce-vulnerability-cve-2021-44228-esa-2021-31/291476):

> Elasticsearch is not susceptible to remote code execution with this vulnerability due to our use of the Java Security Manager. Elasticsearch on JDK8 or below is susceptible to an information leak via DNS which is fixed by a simple JVM property change.

There is no vulnerability if you are running in CleanSpeak Cloud. Deployments there do not allow external access to the ElasticSearch servers. If you need specific version information, please open a support ticket.

If you are self-hosting CleanSpeak, please review the ElasticSearch guidance and your ElasticSearch and Java configurations to ensure you aren't vulnerable.

