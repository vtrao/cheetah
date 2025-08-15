# Kubernetes Module - Cloud Agnostic Kubernetes Cluster

# AWS EKS Cluster
resource "aws_eks_cluster" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name     = "${var.name_prefix}-cluster"
  role_arn = aws_iam_role.cluster[0].arn
  version  = var.kubernetes_version
  
  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks[0].arn
    }
    resources = ["secrets"]
  }
  
  tags = var.tags
  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

# AWS EKS Node Groups
resource "aws_eks_node_group" "main" {
  count = var.cloud_provider == "aws" ? length(var.node_groups) : 0
  
  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.name_prefix}-${var.node_groups[count.index].name}"
  node_role_arn   = aws_iam_role.node_group[0].arn
  subnet_ids      = var.private_subnet_ids
  
  capacity_type  = var.node_groups[count.index].capacity_type
  instance_types = var.node_groups[count.index].instance_types
  
  scaling_config {
    desired_size = var.node_groups[count.index].desired_size
    max_size     = var.node_groups[count.index].max_size
    min_size     = var.node_groups[count.index].min_size
  }
  
  update_config {
    max_unavailable = 1
  }
  
  # Optional: Configure launch template
  dynamic "launch_template" {
    for_each = var.node_groups[count.index].launch_template != null ? [1] : []
    content {
      id      = var.node_groups[count.index].launch_template.id
      version = var.node_groups[count.index].launch_template.version
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.node_groups[count.index].name}"
    Type = "eks-node-group"
  })
  
  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# AWS KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-key"
    Type = "kms-key"
  })
}

resource "aws_kms_alias" "eks" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name          = "alias/${var.name_prefix}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# AWS IAM Roles for EKS
resource "aws_iam_role" "cluster" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name = "${var.name_prefix}-cluster-role"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role" "node_group" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  name = "${var.name_prefix}-node-group-role"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[0].name
}

# GCP GKE Cluster
resource "google_container_cluster" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name     = "${var.name_prefix}-cluster"
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = var.vpc_id
  subnetwork = var.private_subnet_ids[0]
  
  min_master_version = var.kubernetes_version
  
  # Enable network policy
  network_policy {
    enabled = true
  }
  
  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }
  
  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  # Master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All networks"
    }
  }
  
  # Enable Autopilot for fully managed experience (optional)
  # enable_autopilot = true
  
  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
  }
  
  # Enable logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  
  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

# GCP GKE Node Pools
resource "google_container_node_pool" "main" {
  count = var.cloud_provider == "gcp" ? length(var.node_groups) : 0
  
  name       = "${var.name_prefix}-${var.node_groups[count.index].name}"
  location   = var.region
  cluster    = google_container_cluster.main[0].name
  
  initial_node_count = var.node_groups[count.index].min_size
  
  autoscaling {
    min_node_count = var.node_groups[count.index].min_size
    max_node_count = var.node_groups[count.index].max_size
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  node_config {
    preemptible  = var.node_groups[count.index].capacity_type == "SPOT"
    machine_type = var.node_groups[count.index].instance_types[0]
    
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_node[0].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = var.tags
    
    # Enable workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    disk_size_gb = 50
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"
    
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# GCP Service Account for GKE nodes
resource "google_service_account" "gke_node" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  account_id   = "${var.name_prefix}-gke-node"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE nodes"
}

resource "google_project_iam_member" "gke_node" {
  count = var.cloud_provider == "gcp" ? length(local.gcp_node_permissions) : 0
  
  project = var.gcp_project_id
  role    = local.gcp_node_permissions[count.index]
  member  = "serviceAccount:${google_service_account.gke_node[0].email}"
}

# Local values for GCP IAM permissions
locals {
  gcp_node_permissions = var.cloud_provider == "gcp" ? [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer"
  ] : []
}
