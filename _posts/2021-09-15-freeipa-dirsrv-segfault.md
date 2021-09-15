---
layout: posts
title: FreeIPA dirsrv Segfault
---

Our FreeIPA server 4.6.8-5 running on CentOS 7 recently had a problem. We couldn't start the dirsrv service. Investigation in the kernal log revealed a segfault.

```
[16540.924675] ns-slapd[16567]: segfault at 8 ip 00007faf8d341b49 sp 00007ffe84142820 error 4 in libipa_pwd_extop.so[7faf8d332000+2d000]
```

There was <a href="https://freeipa-users.redhat.narkive.com/fpMjXHxI/ns-slapd-hang-segfault" target="_blank">a mailing list thread</a> from about 10 years ago which described a similar segfault. The problem here was some bad formatting in a /etc/krb5.conf file.

Our file didn't have any such issues, but I did notice our file was including some directories:
```
includedir /etc/krb5.conf.d/
includedir /var/lib/sss/pubconf/krb5.include.d/
```

Looking into that second include, I noticed a new file was added recently:
```
root@corp-idm02:/var/lib/sss/pubconf/krb5.include.d# ls -ltr
total 12
-rw-------. 1 root root  0 Aug 27 10:26 localauth_pluginGts2pi
-rw-r--r--. 1 root root 98 Sep 14 17:17 localauth_plugin
-rw-r--r--. 1 root root 35 Sep 14 17:17 krb5_libdefaults
-rw-r--r--. 1 root root 15 Sep 14 17:17 domain_realm_corp_domain_net
```

That `localauth_pluginGts2pi` file was empty and had weird permissions. I ended up removing the file, perhaps fixing the permissions would have solved it as well. This allowed dirsrv to start.
