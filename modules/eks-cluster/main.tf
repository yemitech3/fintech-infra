################################################################################
# 1. PROVIDERS & DATA
################################################################################

provider "aws" {
  region = "us-east-1" 
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

################################################################################
# 2. STORAGE PERMISSIONS (EBS CSI DRIVER)
################################################################################

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi-role"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

################################################################################
# 3. EKS CLUSTER
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  # ✅ This automatically creates the Access Entry for ope1
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  cluster_addons = {
    vpc-cni                = { most_recent = true }
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default_node_group = {
      min_size     = 3
      max_size     = 5
      desired_size = 3
    }
  }

  # ✅ ACCESS ENTRIES - ope1 removed to avoid 409 error
  access_entries = {
    github_runner = {
      principal_arn     = "arn:aws:iam::043310666010:role/github-runner-ssm-role"
      policy_associations = [
        {
          policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope  = { type = "cluster" }
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Owner       = "ope1"
  }
}

################################################################################
# 4. KUBERNETES RESOURCES
################################################################################

resource "kubernetes_namespace" "namespaces" {
  for_each = toset(["fintech", "monitoring", "fintech-dev"])
  metadata {
    name = each.key
  }
  depends_on = [module.eks]
}
