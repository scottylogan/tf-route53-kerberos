Simple Terraform module to create DNS records for Kerberos


## Usage

Minimum configuration:

    module "example_krb5" {
      source  = "github.com/scottylogan/route53-kerberos"
      zone_id = "${aws_route53_zone.example.zone_id}"
    }

This would create records in the _example.com_ domain for the _EXAMPLE.COM_ Kerberos realm:

    _kerberos.example.com.             300 IN TXT "EXAMPLE.COM"

    _kerberos._udp.example.com.        300 IN SRV 0 0  88 kdc-1.example.com.
                                                  0 0  88 kdc-2.example.com.
                                                  0 0  88 kdc-3.example.com.

    _kerberos._tcp.example.com.        300 IN SRV 0 0  88 kdc-1.example.com.
                                                  0 0  88 kdc-2.example.com.
                                                  0 0  88 kdc-3.example.com.

    _kerberos-master._udp.example.com. 300 IN SRV 0 0  88 kdc-1.example.com.

    _kerberos-adm._tcp.example.com.    300 IN SRV 0 0 749 kdc-1.example.com.

    _kpasswd._udp.example.com.         300 IN SRV 0 0 464 kdc-1.example.com.

## Variables

### zone_id

ID of AWS Route53 Hosted Zone to update (*REQUIRED*). The domain name
is retrieved from the hosted zone definition.

### realm

Name of the Kerberos Realm. Defaults to the domain name in upper case.

### prefix

Prefix to be used to create KDC server names for SRV record targets.  Defaults to _kdc_.

### master_name

Name of the master KDC. Defaults to the first KDC (_kdc-1.DOMAIN_)

### ttl

Defines the DNS record TTL (in seconds). Defaults to _300_.

### kdcs

Number of KDC targets to create for the SRV records. Defaults to the
number of availability zones in the current AWS region.

### kpasswd

Controls the creation of the `_kpasswd._udp` SRV record. Defaults to _true_.

### kadmin

Controls the creation of the `_kerberos-adm._tcp` SRV record. Defaults to _true_.


## Configuration Example

For historical reasons, Stanford has used a lower-case Kerberos 5 realm
name. Also, since our IT Lab development domain is used for development
and testing, we don't allow password changes via `kpasswd`, and we want
shorter DNS TTLs:

    module "dev_kerberos" {
      source  = "github.com/scottylogan/route53-kerberos"
      zone_id = "${aws_route53_zone.dev.zone_id}"
      realm   = "dev.itlab.stanford.edu"
      ttl     = "30"
      kpasswd = false
    }

