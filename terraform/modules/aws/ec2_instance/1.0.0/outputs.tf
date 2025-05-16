output "eips" {
  value = { for idx, eip in aws_eip.eip : var.name => eip.public_ip }
}

output "instance_pubip" {
  value = aws_instance.instance.public_ip
}

output "instance_prvip" {
  value = aws_instance.instance.private_ip
}

output "instance_arn" {
  value = aws_instance.instance.arn
}
