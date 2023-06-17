output "LB-Name" {
  value = aws_lb.alb.dns_name
}

output "CloudFront-Domain" {
  value = aws_cloudfront_distribution.alb_distribution.domain_name
}