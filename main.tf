# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password
terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "3.0.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "3.21.0"
    }
  }
}

provider "random" {
}

provider "aws" {
}

resource "random_password" "password" {
  length = 16
  special = true
}

resource "aws_iam_role" "RedisLabsClusterNodeRole" {
    name = "redislabs-cluster-node-role"
    assume_role_policy = <<-EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
    EOT
    description = "Role used by EC2 instances managed by RedisLabs"
    tags = {
	UsedBy = "RedisLabs"
    }
}

resource "aws_iam_instance_profile" "RedisLabsClusterNodeRoleInstanceProfile" {
  name = "redislabs-cluster-node-role"
  role = aws_iam_role.RedisLabsClusterNodeRole.name
}

data "aws_s3_bucket_object" "RedisLabsInstanceRolePolicy"  {
  bucket = "cloudformation-templates.redislabs.com"
  key    = "RedisLabsInstanceRolePolicy.json"
}

resource "aws_iam_policy" "RedisLabsInstanceRolePolicy" {
    name = "RedisLabsInstanceRolePolicy"
    description = "Instance role policy used by Redislabs for its cluster members"
    policy = data.aws_s3_bucket_object.RedisLabsInstanceRolePolicy.body
}
    
resource "aws_iam_role_policy_attachment" "cluster-node-role-attach" {
  role       = aws_iam_role.RedisLabsClusterNodeRole.name
  policy_arn = aws_iam_policy.RedisLabsInstanceRolePolicy.arn
}

data "aws_s3_bucket_object" "RedislabsIAMUserRestrictedPolicy" {
  bucket = "cloudformation-templates.redislabs.com"
  key    = "RedisLabsIAMUserRestrictedPolicy.json"
}

resource "aws_iam_policy" "RedislabsIAMUserRestrictedPolicy" {
    name = "RedislabsIAMUserRestrictedPolicy"
    description = "Policy used by RedisLabs users"
    policy = data.aws_s3_bucket_object.RedislabsIAMUserRestrictedPolicy.body

}

resource "aws_iam_user" "RedisLabsUser" {
    name = "redislabs-user"
    tags = {
	UsedBy = "RedisLabs"
    }
}

resource "aws_iam_user_login_profile" "RedisLabsUserLoginProfile" {
  user    = aws_iam_user.RedisLabsUser.name
  pgp_key = "keybase:toby_h_ferguson"
  password_reset_required = false
}

resource "aws_iam_user_policy_attachment" "RedisLabsUserPolicyAttachment" {
  user       = aws_iam_user.RedisLabsUser.name
  policy_arn = aws_iam_policy.RedislabsIAMUserRestrictedPolicy.arn
}

resource "aws_iam_access_key" "RedisLabsUserAccessKey" {
    user = aws_iam_user.RedisLabsUser.name
    pgp_key = "keybase:toby_h_ferguson"
}

resource "aws_iam_role" "RedisLabsCrossAccountRole" {
    name = "redislabs-role"
    description = "String"
    assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::168085023892:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
    EOT
    tags = {
	UsedBy = "RedisLabs"
    }
}

resource "aws_iam_role_policy_attachment" "cross-account-role-attach" {
  role       = aws_iam_role.RedisLabsCrossAccountRole.name
  policy_arn = aws_iam_policy.RedislabsIAMUserRestrictedPolicy.arn
}



