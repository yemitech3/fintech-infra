variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "043310666010"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment where resources are deployed"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_oidc_provider" {
  description = "EKS OIDC provider (e.g. oidc.eks.us-west-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E)"
  type        = string
}

variable "tags" {
  description = "Common tags for the cluster resources"
  type        = map(string)
  default = {
    terraform = "true"
  }
}
