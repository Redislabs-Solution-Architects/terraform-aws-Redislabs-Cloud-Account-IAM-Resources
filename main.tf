terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.21.0"
    }
    rediscloud = {
      source = "RedisLabs/rediscloud"
      version = "0.2.1"
    }
  }
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

resource "aws_iam_policy" "RedisLabsInstanceRolePolicy" {
    name = "RedisLabsInstanceRolePolicy"
    description = "Instance role policy used by Redislabs for its cluster members"
    policy = file("${path.module}/policies/RedisLabsInstanceRolePolicy.json")
}
    
resource "aws_iam_role_policy_attachment" "cluster-node-role-attach" {
  role       = aws_iam_role.RedisLabsClusterNodeRole.name
  policy_arn = aws_iam_policy.RedisLabsInstanceRolePolicy.arn
}

resource "aws_iam_policy" "RedislabsIAMUserRestrictedPolicy" {
    name = "RedislabsIAMUserRestrictedPolicy"
    description = "Policy used by RedisLabs users"
    policy = file("${path.module}/policies/RedislabsIAMUserRestrictedPolicy.json")
}

resource "aws_iam_user" "RedisLabsUser" {
    name = "redislabs-user"
    tags = {
	UsedBy = "RedisLabs"
    }
}

resource "aws_iam_user_login_profile" "RedisLabsUserLoginProfile" {
  user    = aws_iam_user.RedisLabsUser.name
  pgp_key = var.pgp_key
  password_reset_required = false
}

resource "aws_iam_user_policy_attachment" "RedisLabsUserPolicyAttachment" {
  user       = aws_iam_user.RedisLabsUser.name
  policy_arn = aws_iam_policy.RedislabsIAMUserRestrictedPolicy.arn
}

resource "aws_iam_access_key" "RedisLabsUserAccessKey" {
    user = aws_iam_user.RedisLabsUser.name
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



