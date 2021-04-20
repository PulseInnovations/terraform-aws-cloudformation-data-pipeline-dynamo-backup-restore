# Terraform module for DynamoDB Backup

This module wraps Cloudformation due to lack of Data Pipeline support within Terraform itself. It creates the required IAM roles for EMR/Data Pipeline to backup a single DynamoDB table to S3 in a format which is restorable.

Things of note:

* EMR 6.1.0 is used not the latest version of 6.2.0, this is due to compatibility issues between Data Pipeline and EMR
* It does work with On Demand provisioning in which case the read_throughput_ratio variable can be ignored
* It is up to you to provide the Subnet, S3 bucket and SNS topic used to alerting

You must have the aws provider configuration with a region at the bare minimum e.g.

```
provider "aws" {
  region  = var.aws-region
}
```

