---
layout: posts
title: GnuTLS, a Thawte CA certificate and CVE-2015-7575
---

### TLDR;
If a server is using a certificate chain signed by the Thawte Premium Server CA
(*SHA1
Fingerprint=62:7F:8D:78:27:65:63:99:D2:7D:7F:90:44:C9:FE:B3:F3:3E:FA:9A*) AND
that server is distributing that certificate as part of its CA chain, clients
using libgnutls26 will not establish a connection. This library does not allow
RSA+MD5 certificates and this root CA certificate is such a certificate. Good news
though, simply replace the installed certificate with the SHA1 version available from 
their website.

<a href='https://search.thawte.com/support/ssl-digital-certificates/index?page=content&id=AR1470' target="_blank">https://search.thawte.com/support/ssl-digital-certificates/index?page=content&id=AR1470</a>

-----------------------------------------------------------

### Overview

*I suddenly could not send email using Mutt and some of my colleagues reported
similar issues with their Claws email clients as well, what was going on?*

At the time of writing we were using Ubuntu 12.04 at work and there had
recently been an update to the libgnutls26 package, this affected both the
Claws and Mutt email clients as they both happened to being libgnutls.

> gnutls26 (2.12.14-5ubuntu3.11) precise-security; urgency=medium
>
>  * SECURITY UPDATE: incorrect RSA+MD5 support with TLS 1.2
>    - debian/patches/CVE-2015-7575.patch: do not consider any values from
>      the extension data to decide acceptable algorithms in
>      lib/ext_signature.c.
>    - CVE-2015-7575

This patch effectively disables the use of RSA+MD5 certificates provided by the
server. *Note that root CA certs on the client can still be using this
signature algorithm.*

It turned out that on one of the mail servers in our cluster, the SMTP daemon
was configured to provide the root CA certificate as part of its intermediate
chain. So the server was providing its own certificate, the two
required intermediate certificates and the superfluous root certificate.

In case you are unaware why the server does not need to provide the root
certificate it is because the client has to already have a copy of the root
certificate locally so that it can verify the identity of the certificate chain
passed from the server. These root certificates are distributed by various
software vendors and are built into things like your browser. A good example of
one of these vendors is
<a href='https://www.mozilla.org/en-US/about/governance/policies/security-group/certs/' target='_blank'>Mozilla</a>.

So when the server provided the root CA certificate as part of the chain,
GnuTLS could see that this certificate was using an RSA+MD5 signature algorithm
and it would not allow the connection to proceed at all and simply output an
obscure message:

> gnutls_handshake: The signature algorithm is not supported
>
> Could not negotiate TLS connection

### Fixing the problem
*NOTE: this will have an emphasis on Ubuntu 12.04 but what you need to do is the same, even if the commands are not.*

**First of all, the easiest fix is simply do not have the server include the
unneeded root CA certificate in the chain it provides to the client. Done!**

If for some reason (may it be technical or political) you cannot simply apply
the easy fix, there is another way to correct this. Thawte actually has a
replacement RSA+SHA1 certificate available from their website that we can use
to swap out for the RSA+MD5 certificate. You can download this certificate from
the following location.

<a href='https://search.thawte.com/support/ssl-digital-certificates/index?page=content&id=AR1470' target="_blank">https://search.thawte.com/support/ssl-digital-certificates/index?page=content&id=AR1470</a>

I recommend downloading the certificate and saving it to a file in your
`/usr/share/ca-certificates/` directory.

Next up, you have the option to manually edit the `/etc/ca-certificates.conf`
file to remove the bad certificate, re-add the new certificate and then run
`update-ca-certificates`. I like to mention this method just because it could
be better for those of you using configuration management software.

An alternative method and also potentially easier if you are only doing this
once would be to run the following command. Once prompted simply select `ask`.
It will prompt you again, this time to enable or disable different root
certificates in your root store. Simply deselect the
`mozilla/Thawte_Premium_Server_CA.crt` certificate and then enable your new
certificate in the same menu.

    dpkg-reconfigure ca-certificates

This will ensure your server is now providing the RSA+SHA1 version of the
Thawte Premium Server CA certificate and the GnuTLS library on the client side
should be happy. It will also ensure that your server is still able to verify
the identity of any other servers it tries to connect securely to if they are
using a certificate tied to this root.


