---
title: "HackTheBox - Waldo"
date: 2020-02-15T00:07:26-08:00
categories:
- HackTheBox
tags:
- security
keywords:
- pentesting
- Labs
- HackTheBox
- Waldo
draft: true
autoThumbnailImage: false
coverImage: /images/HackTheBox/Waldo/Waldo.png
---

|  Event | Challenge | OS | Difficulty | IP |
|:----------:|:------------:|:------------:|:------------:|:------------:|
| HackTheBox |  Waldo  |  Linux  | Medium |  10.10.10.87  |

<!--toc-->
<!--more-->

# Summary
Waldo was such a great box. It was not very world realist but I learned a lot from this machine.

# Start
Starting off, the first thing I did was run a quick nmap scan. Looking at the results, only 2 ports were open.
`nmap 10.10.10.87 -oN quick-scan`
```
PORT    STATE SERVICE VERSION
22/SSH  open  ssh     OpenSSH 7.5 (protocol 2.0)
80/http open  http    nginx 1.12.2
```

I loaded Burp and started tinkering with the Where's-Waldo-themed website running a custom application called _List Manager_. Looking at the web requests, two requests stood out to me: _readDir_ from `dirRead.php` and _readFile_ from `fileRead.php`.
``` http
POST /dirRead.php HTTP/1.1
Host: 10.10.10.87
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0
Accept: */*
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate
Referer: http://10.10.10.87/list.html
Content-type: application/x-www-form-urlencoded
Content-Length: 54
Connection: close

path=./.list/
```
