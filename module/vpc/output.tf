output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(aws_vpc.production.id, null)
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = try(aws_vpc.production.arn, null)
}