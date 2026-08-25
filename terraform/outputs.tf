output "instance_public_ip" {
  value = aws_instance.app.public_ip
}

output "instance_id" {
  value = aws_instance.app.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "route53_nameservers" {
  description = "Nameservers to set at your domain registrar (only populated if domain_name is set)"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}

output "private_key_pem" {
  value     = tls_private_key.main.private_key_pem
  sensitive = true
}
