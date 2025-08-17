# Cheetah Platform Instructions

## Overview

Cheetah is a cloud-agnostic infrastructure platform designed for secure, automated deployment of full-stack applications. It supports AWS, GCP, and Azure, and integrates with enterprise-grade secrets management and Kubernetes orchestration.

## Key Features

- **Multi-Cloud Support**: Deploy to AWS, GCP, or Azure using a unified workflow.
- **Security-First**: Integrates with cloud-native secret stores (AWS SSM, GCP Secret Manager, Azure Key Vault). No plaintext secrets in code.
- **Kubernetes Native**: Provisions managed Kubernetes clusters (EKS, GKE, AKS).
- **Database Automation**: Supports managed PostgreSQL (RDS, Cloud SQL, Azure Database for PostgreSQL).
- **Terraform-Based**: All infrastructure is managed as code via Terraform modules.
- **Git Submodule Integration**: Designed to be used as a submodule in application repositories.

## Usage

### 1. Cloning with Submodules

Always clone the parent repository with submodules:
