data "aws_availability_zones" "azs" {}

data "aws_route53_zone" "krb5" {
  zone_id = "${var.zone_id}"
}

variable "zone_id" {
  type = "string"
  description = "AWS Route53 ZoneID"
}

variable "prefix" {
  type = "string"
  description = "Name prefix for KDC targets in SRV records"
  default = "kdc"
}

variable "master_name" {
  type = "string"
  description = "master KDC name"
  default = ""
}

variable "realm" {
  type = "string"
  description = "Kerberos realm name"
  default = ""
}

variable "ttl" {
  type = "string"
  default = "300"
  description = "DNS Record TTL"
}

variable "kdcs" {
  type = "string"
  default = "0"
  description = "Number of KDC targets to create for SRV records"
}

variable "kpasswd" {
  default = true
  description = "Control the creation of the _kpasswd._udp SRV record"
}

variable "kadmin" {
  default = true
  description = "Control the creation of the _kerberos-adm._tcp SRV record"
}

resource "aws_route53_record" "krb5-txt" {
  zone_id = "${var.zone_id}"
#  name    = "_kerberos.${var.domain}"
  name    = "_kerberos.${data.aws_route53_zone.krb5.name}"
  type    = "TXT"
  ttl     = "${var.ttl}"
  
  records = [
    "${var.realm == "" ? upper(data.aws_route53_zone.krb5.name) : var.realm}"
  ]
}

data "template_file" "kdc_records" {
  count = "${var.kdcs == "0" ? length(data.aws_availability_zones.azs.names) : var.kdcs}"
  template = "0 0 88 $${kdc_name}"
  vars {
    kdc_name = "${format("%s-%d.%s", var.prefix, count.index + 1, data.aws_route53_zone.krb5.name)}"
  }
}

data "template_file" "master_name" {
  template = "$${kdc_name}"
  vars {
    kdc_name = "${format("%s.%s", var.master_name == "" ? format("%s-1", var.prefix) : var.master_name, data.aws_route53_zone.krb5.name)}"
  }
}

resource "aws_route53_record" "krb5-tcpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos._tcp.${data.aws_route53_zone.krb5.name}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  records = ["${data.template_file.kdc_records.*.rendered}"]
}

resource "aws_route53_record" "krb5-udpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos._udp.${data.aws_route53_zone.krb5.name}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  records = ["${data.template_file.kdc_records.*.rendered}"]
}

resource "aws_route53_record" "krb5-master-udpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos-master._udp.${data.aws_route53_zone.krb5.name}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 88 ${data.template_file.master_name.rendered}"
  ]
}

resource "aws_route53_record" "krb5-adm-tcpsrv" {
  count   = "${var.kadmin ? 1 : 0}"
  zone_id = "${var.zone_id}"
  name    = "_kerberos-adm._tcp.${data.aws_route53_zone.krb5.name}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 749 ${data.template_file.master_name.rendered}"
  ]
}

resource "aws_route53_record" "krb5-kpasswd-udpsrv" {
  count   = "${var.kpasswd ? 1 : 0}"
  zone_id = "${var.zone_id}"
  name    = "_kpasswd._udp.${data.aws_route53_zone.krb5.name}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 464 ${data.template_file.master_name.rendered}"
  ]
}
