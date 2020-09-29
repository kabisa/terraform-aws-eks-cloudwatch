# terraform-aws-eks-cloudwatch

This module requires our [openid connect module](https://github.com/kabisa/terraform-aws-eks-openid-connect)

Example usage:

```hcl-terraform
module "eks-cloudwatch" {
  source                  = "git@github.com:kabisa/terraform-aws-eks-cloudwatch.git?ref=1.0"
  depends_on              = [module.eks, module.eks_openid_connect]
  account_id              = var.account_id
  eks_cluster_name        = var.eks_cluster_name
  enable_cloudwatch_agent = true
  enable_logs_forwarding  = true
  oidc_host_path          = module.eks_openid_connect.oidc_host_path
  region                  = var.region
}
```