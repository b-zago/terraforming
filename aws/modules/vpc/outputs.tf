output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = { for k, v in aws_subnet.public : k => v.id } }
output "private_subnet_ids" { value = { for k, v in aws_subnet.private : k => v.id } }
output "nat_public_ip" { value = try(aws_eip.this[0].public_ip, null) }
