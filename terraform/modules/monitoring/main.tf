# Monitoring Module - Cloud Agnostic Observability

# AWS CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name              = "/aws/eks/${var.cluster_name}"
  retention_in_days = 7
  
  tags = var.tags
}

# AWS CloudWatch Dashboard (optional)
resource "aws_cloudwatch_dashboard" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  dashboard_name = "${var.name_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_request_count", "ClusterName", var.cluster_name],
            ["AWS/EKS", "cluster_request_total", "ClusterName", var.cluster_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.region
          title   = "EKS Cluster Metrics"
        }
      }
    ]
  })
  
  tags = var.tags
}

# GCP Operations Suite (Stackdriver) - Placeholder
resource "google_logging_project_sink" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name        = "${var.name_prefix}-log-sink"
  destination = "storage.googleapis.com/${var.name_prefix}-logs-bucket"
  
  filter = "resource.type=gke_cluster"
}

# Output logging endpoint for AWS
output "log_group_name" {
  value = var.cloud_provider == "aws" ? (length(aws_cloudwatch_log_group.main) > 0 ? aws_cloudwatch_log_group.main[0].name : "") : ""
}

# Output dashboard URL for AWS
output "dashboard_url" {
  value = var.cloud_provider == "aws" ? (length(aws_cloudwatch_dashboard.main) > 0 ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : "") : ""
}
