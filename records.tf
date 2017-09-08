data "aws_availability_zones" "azs" {}

data "aws_route53_zone" "krb5" {
  name = "${var.domain}."
}

data "aws_route53_zone" "target" {
  name = "${var.target_domain == "" ? var.domain : var.target_domain}."
}

variable "domain" {
  type = "string"
  description = "Domain to host DNS records"
  default = ""
}

variable "target_domain" {
  type = "string"
  description = "Domain for DNS SRV record targets"
  default = ""
}

variable "prefix" {
  type = "string"
  description = "Name prefix for KDC targets in SRV records"
  default = "kdc"
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
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
#  name    = "_kerberos.${var.domain}"
  name    = "_kerberos.${var.domain}"
  type    = "TXT"
  ttl     = "${var.ttl}"
  
  records = [
    "${var.realm == "" ? upper(var.domain) : var.realm}"
  ]
}

data "template_file" "target_name" {
  template = "$${t_name}"
  vars {
    t_name = "${var.target_domain == "" ? var.domain : var.target_domain}."
  }
}

data "template_file" "kdc_records" {
  count = "${var.kdcs == "0" ? length(data.aws_availability_zones.azs.names) : var.kdcs}"
  template = "$${priority} 0 88 $${kdc_name}"
  vars {
    kdc_name = "${format("%s-%d.%s", var.prefix, count.index, data.template_file.target_name.rendered)}"
    priority = "${count.index == 0 ? 10 : 0}"
  }
}

data "template_file" "master_name" {
  template = "$${kdc_name}"
  vars {
    kdc_name = "${format("%s-0.%s", var.prefix, data.template_file.target_name.rendered)}"
  }
}

resource "aws_route53_record" "krb5-tcpsrv" {
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
  name    = "_kerberos._tcp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  records = ["${data.template_file.kdc_records.*.rendered}"]
}

resource "aws_route53_record" "krb5-udpsrv" {
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
  name    = "_kerberos._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  records = ["${data.template_file.kdc_records.*.rendered}"]
}

resource "aws_route53_record" "krb5-master-udpsrv" {
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
  name    = "_kerberos-master._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 88 ${data.template_file.master_name.rendered}"
  ]
}

resource "aws_route53_record" "krb5-master-alias" {
  zone_id = "${data.aws_route53_zone.target.zone_id}"
  name    = "${format("%s-master.%s", var.prefix, data.template_file.target_name.rendered)}"
  type    = "A"

  alias {
    name                   = "${data.template_file.master_name.rendered}"
    zone_id                = "${data.aws_route53_zone.target.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "krb5-adm-tcpsrv" {
  count   = "${var.kadmin ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
  name    = "_kerberos-adm._tcp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 749 ${data.template_file.master_name.rendered}"
  ]
}

resource "aws_route53_record" "krb5-kpasswd-udpsrv" {
  count   = "${var.kpasswd ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.krb5.zone_id}"
  name    = "_kpasswd._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 464 ${data.template_file.master_name.rendered}"
  ]
}
