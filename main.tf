terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "data_pipeline_default_resource_role" {
  name     = "backup-${var.table_name}-ec2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "data_pipeline_default_resource_role" {
  role       = aws_iam_role.data_pipeline_default_resource_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforDataPipelineRole"
}
resource "aws_iam_instance_profile" "data_pipeline_default_resource_role" {
  name = "backup-${var.table_name}-ec2"
  role = aws_iam_role.data_pipeline_default_resource_role.name
}

resource "aws_iam_policy" "data_pipeline_default_role" { 
  name     = "backup-${var.table_name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetInstanceProfile",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:PassRole"
            ],
            "Resource": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/backup-${var.table_name}",
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/backup-${var.table_name}-ec2"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CancelSpotInstanceRequests",
                "ec2:CreateNetworkInterface",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteTags",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeImages",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstances",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeLaunchTemplates",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribePrefixLists",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSpotInstanceRequests",
                "ec2:DescribeSpotPriceHistory",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVpcAttribute",
                "ec2:DescribeVpcEndpoints",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DescribeVpcs",
                "ec2:DetachNetworkInterface",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:RequestSpotInstances",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes",
                "elasticmapreduce:TerminateJobFlows",
                "elasticmapreduce:ListSteps",
                "elasticmapreduce:ListClusters",
                "elasticmapreduce:RunJobFlow",
                "elasticmapreduce:DescribeCluster",
                "elasticmapreduce:AddTags",
                "elasticmapreduce:RemoveTags",
                "elasticmapreduce:ListInstanceGroups",
                "elasticmapreduce:ModifyInstanceGroups",
                "elasticmapreduce:GetCluster",
                "elasticmapreduce:DescribeStep",
                "elasticmapreduce:AddJobFlowSteps",
                "elasticmapreduce:ListInstances",
                "iam:ListInstanceProfiles",
                "redshift:DescribeClusters"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "sns:GetTopicAttributes",
                "sns:Publish"
            ],
            "Resource": [
                "${var.sns_topic_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListMultipartUploads"
            ],
            "Resource": [
              "arn:aws:s3:::${var.s3_bucket}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectMetadata",
                "s3:PutObject"
            ],
            "Resource": [
              "arn:aws:s3:::${var.s3_bucket}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Scan",
                "dynamodb:DescribeTable"
            ],
            "Resource": [
                "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:${data.aws_caller_identity.current.account_id}:table/${var.table_name}"
            ]
        }
    ]
}
EOF
}
resource "aws_iam_role" "data_pipeline_default_role" {
  name     = "backup-${var.table_name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "datapipeline.amazonaws.com",
          "elasticmapreduce.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "data_pipeline_default_role" {
  role       = aws_iam_role.data_pipeline_default_role.name
  policy_arn = aws_iam_policy.data_pipeline_default_role.arn
}

data "template_file" "data_pipeline_dynamo_backup_template" {
    template = file("${path.module}/datapipeline-backup-dynamo-cf.json")

    vars = {
        table_name              = var.table_name
        table_region            = var.region
        read_throughput_ratio   = var.read_throughput_ratio
        subnet_id               = var.subnet_id
        terminate_after         = var.terminate_after
        s3_path                 = "s3://${var.s3_bucket}/${var.table_name}"
        schedule_period         = var.schedule
        sns_topic_arn           = var.sns_topic_arn
        default_role            = aws_iam_role.data_pipeline_default_role.name
        resource_role           = aws_iam_role.data_pipeline_default_resource_role.name
        emr_instance_type       = var.emr_instance_type
    }

    depends_on = [
      aws_iam_instance_profile.data_pipeline_default_resource_role,
      aws_iam_role_policy_attachment.data_pipeline_default_resource_role,
      aws_iam_role.data_pipeline_default_resource_role,
      aws_iam_role_policy_attachment.data_pipeline_default_role,
      aws_iam_role.data_pipeline_default_role
    ]
}

resource "aws_cloudformation_stack" "module_data_pipeline_backup_stack" {
    name          = "backup-${var.table_name}"
    template_body = data.template_file.data_pipeline_dynamo_backup_template.rendered
}
