# Local values for cross-cloud compatibility
locals {
  # Map generic availability zones to cloud-specific ones
  az_mapping = {
    aws = var.availability_zones != [] ? var.availability_zones : [
      "${var.region}a",
      "${var.region}b",
      "${var.region}c"
    ]
    gcp = var.availability_zones != [] ? var.availability_zones : [
      "${var.region}-a",
      "${var.region}-b",
      "${var.region}-c"
    ]
    azure = var.availability_zones != [] ? var.availability_zones : [
      "1", "2", "3"
    ]
  }
  
  availability_zones = slice(local.az_mapping[var.cloud_provider], 0, 2)
}

# AWS VPC
resource "aws_vpc" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# AWS Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# AWS Public Subnets
resource "aws_subnet" "public" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index % length(local.availability_zones)]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

# AWS Private Subnets
resource "aws_subnet" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = local.availability_zones[count.index % length(local.availability_zones)]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private"
  })
}

# AWS NAT Gateway
resource "aws_eip" "nat" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0
  
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-gw-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# AWS Route Tables
resource "aws_route_table" "public" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

# AWS Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.cloud_provider == "aws" ? length(var.public_subnet_cidrs) : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.cloud_provider == "aws" ? length(var.private_subnet_cidrs) : 0
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# GCP VPC
resource "google_compute_network" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# GCP Subnets
resource "google_compute_subnetwork" "public" {
  count = var.cloud_provider == "gcp" ? length(var.public_subnet_cidrs) : 0
  
  name          = "${var.name_prefix}-public-subnet-${count.index + 1}"
  ip_cidr_range = var.public_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.main[0].name
  
  # Enable private Google access
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  count = var.cloud_provider == "gcp" ? length(var.private_subnet_cidrs) : 0
  
  name          = "${var.name_prefix}-private-subnet-${count.index + 1}"
  ip_cidr_range = var.private_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.main[0].name
  
  # Enable private Google access
  private_ip_google_access = true
}

# GCP Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name    = "${var.name_prefix}-allow-internal"
  network = google_compute_network.main[0].name
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_ssh" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name    = "${var.name_prefix}-allow-ssh"
  network = google_compute_network.main[0].name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# GCP Router and NAT
resource "google_compute_router" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = google_compute_network.main[0].id
}

resource "google_compute_router_nat" "main" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  
  name   = "${var.name_prefix}-nat"
  router = google_compute_router.main[0].name
  region = var.region
  
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
