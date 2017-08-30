data "aws_availability_zones" "azs" {}

variable "zone_id" {
  type = "string"
  description = "Route53 ZoneID"
}

variable "domain" {
  type = "string"
  description = "Domain Name"
}

variable "kdc_name" {
  type = "string"
  description = "kdc name prefix"
  default = "kdc"
}

variable "kdc_master_name" {
  type = "string"
  description = "master KDC name"
  default = "kdc-master"
}

variable "ttl" {
  type = "string"
  default = "300"
  description = "DNS Record TTL"
}

variable "kdc_srv_records" {
  type = "list"
  default = "${formatlist("0 0 88 ${var.kdc_name}-%s.%s", ${data.aws_availability_zones.available.names}, ${var.domain})}"
}

resource "aws_route53_record" "krb5-txt" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos.${var.domain}"
  type    = "TXT"
  ttl     = "${var.ttl}"
  
  records = [
    "${var.domain}"
  ]
}

resource "aws_route53_record" "krb5-tcpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos._tcp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = "${kdc_srv_records}"
}

resource "aws_route53_record" "krb5-udpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = "${kdc_srv_records}"
}

resource "aws_route53_record" "krb5-master-udpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos-master._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 88 ${var.kdc_master_name}.${var.domain}."
  ]
}

resource "aws_route53_record" "krb5-adm-tcpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kerberos-adm._tcp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 749 ${var.kdc_master_name}.${var.domain}."
  ]
}

resource "aws_route53_record" "krb5-kpasswd-udpsrv" {
  zone_id = "${var.zone_id}"
  name    = "_kpasswd._udp.${var.domain}"
  type    = "SRV"
  ttl     = "${var.ttl}"
  
  records = [
    "0 0 464 ${var.kdc_master_name}.${var.domain}."
  ]
}
