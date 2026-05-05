output "instance1_public_ip" {
  value = aws_instance.ec2-1.public_ip
}

output "instance1_id" {
  value = aws_instance.ec2-1.id
}

output "instance2_public_ip" {
  value = aws_instance.ec2-2.public_ip
}

output "instance2_id" {
  value = aws_instance.ec2-2.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.id
}
output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}