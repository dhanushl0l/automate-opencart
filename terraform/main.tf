terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = "ascode-vpc"
  cidr = "10.123.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]

  enable_nat_gateway = true

  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = "ascode-cluster1"
  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    opencart-nodes = {
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.ascode.token
}

data "aws_eks_cluster_auth" "ascode" {
  name = module.eks.cluster_name
}

resource "kubernetes_deployment" "opencart" {
  metadata {
    name      = "opencart"
    namespace = "default"
    labels    = { app = "opencart" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "opencart" }
    }

    template {
      metadata {
        labels = { app = "opencart" }
      }

      spec {
        container {
          name  = "opencart"
          image = "ghcr.io/dhanushl0l/opencart:latest"

          port {                
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "opencart" {
  metadata {
    name      = "opencart-service"
    namespace = "default"
  }

  spec {
    selector = { app = kubernetes_deployment.opencart.metadata[0].labels.app }
    type     = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "opencart_db" {
  metadata {
    name      = "opencart-db"
    namespace = "default"
    labels    = { app = "opencart-db" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "opencart-db" }
    }

    template {
      metadata {
        labels = { app = "opencart-db" }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "rootpassword"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "opencart"
          }
          env {
            name  = "MYSQL_USER"
            value = "opencartuser"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "opencartpass"
          }

          port {
            container_port = 3306
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "opencart_db_svc" {
  metadata {
    name      = "opencart-db"
    namespace = "default"
  }

  spec {
    selector = { app = "opencart-db" }

    port {
      port        = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
}

output "opencart_lb_ip" {
  value = kubernetes_service.opencart.status[0].load_balancer[0].ingress[0].hostname
}