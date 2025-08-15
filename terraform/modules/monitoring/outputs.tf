output "log_group_name" {
  description = "CloudWatch log group name"
  value       = var.cloud_provider == "aws" ? (length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].name : "") : ""
}

output "dashboard_url" {
  description = "Monitoring dashboard URL"
  value       = var.cloud_provider == "aws" ? (length(aws_cloudwatch_dashboard.main) > 0 ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : "") : ""
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = true
}
