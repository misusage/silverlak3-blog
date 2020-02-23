---
title: "Hello World: CTF Edition"
date: 2019-04-27T23:31:29+02:00
draft: true
tags:
- setup
categories:
- posts
- write-ups
keywords:
- hello-world
coverSize: partial
coverMeta: in
coverImage: /images/banner.jpg
autoThumbnailImage: false
---

|  Event | Challenge | Category | Points | Solves |
|:----------:|:------------:|:------------:|:------------:|:------------:|
| some-ctf |  welcome  |  web  | 100 |  122  |

<!--toc-->
<!--more-->

To add a table of contents, literally just add this to the top of the page. `<!--toc-->`

# TL;DR

Made this file to make it easy to produce new pages. Just copy, paste, edit, then push.

# HELLO WORLD CTF EDITION

Which CTF are you doing? Just look at the source for this page to see how to type stuff.

After downloading the file {{< hl-text orange >}}some-highlighted-file.zip{{< /hl-text >}}, open the file. You must eat cereal. You can insert a code block below just like this:

{{< codeblock lang="bash"  >}}
$ strings some-file | grep "Linux version"
Linux version %d.%d.%d
Linux version 3.16.0-6-amd64 (debian-kernel@lists.debian.org) (gcc version 4.9.2 (Debian 4.9.2-10+deb8u1) ) #1 SMP Debian 3.16.57-2 (2018-07-14)
{{< /codeblock >}}

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

A different style of code block:
{{< tabbed-codeblock hello >}}
<!-- tab bash-->
  $ strings some-file | grep "Linux version"
  Linux version %d.%d.%d
  Linux version 3.16.0-6-amd64 (debian-kernel@lists.debian.org) (gcc version 4.9.2 (Debian 4.9.2-10+deb8u1) ) #1 SMP Debian 3.16.57-2 (2018-07-14)
<!-- endtab -->
<!-- tab css -->
        .btn {
            color: red;
        }
    <!-- endtab -->
{{< /tabbed-codeblock >}}

Here is a [link](https://github.com/silverlak3). This is how you add it.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

To add some bulleted lists, add the following:

- A debian distribution
- The right version of the kernel
- Additional tools

Another cool code block, bash flavored:
{{< codeblock lang="bash" >}}
$ uname -a
Linux ubuntu 4.9.0-8-amd64 #1 SMP Debian 4.9.131-2 (2017-10-27) x86_64 GNU/Linux
{{< /codeblock >}}

# Another Section

Here's how to highlight stuff:

{{< hl-text danger >}}
your highlighted text
{{< /hl-text >}}
{{< hl-text primary >}}
your highlighted text
{{< /hl-text >}}
{{< hl-text cyan >}}
your highlighted text
{{< /hl-text >}}
{{< hl-text purple >}}
your highlighted text
{{< /hl-text >}}
{{< hl-text green >}}
your highlighted text
{{< /hl-text >}}

Use any of the following classes:
```
red
green
blue
purple
orange
yellow
cyan
primary
success
warning
danger

...and add it to the block.
{{< hl-text class >}}your highlighted text{{< /hl-text >}}
```

Here's a different style of code block. This one doesn't have numbers on the side.
```
user@ubuntu~: cat /dev/null
user@ubuntu~: ifconfig
...
```
To add pictures, first add your picture to the static folder:

1. `mv image.jpg /static/images/somefolder/`
2. Add the picture with the code block below.
3. Then compile the page.

## A Subsection
Here is a cool picture:
{{< image classes="fancybox fig-100 center" src="/images/hello-world/flag-art.jpg" thumbnail="/images/hello-world/flag-art.jpg" title="Awesome picture">}}

Ok so we got something else here so let's try to understand this. We have a common URL which will be highlighted {{< hl-text orange >}}google.com{{< /hl-text >}}. Now, lets quote something from that page.

### dank.py
{{< blockquote >}}
Dank.py (is provided AS IS), is a proof of concept to perform nothing using memes at the same time.
{{< /blockquote >}}

{{< blockquote >}}
In order to use dank.py, you will need to configure it and add your proper settings (eg. SSH, AES512 encryption passphrase and so on).
{{< /blockquote >}}

And we have our flag : {{< hl-text red >}}ctf{y0u_l0v3_f14gs_d0n7_y0u}{{< /hl-text >}}
