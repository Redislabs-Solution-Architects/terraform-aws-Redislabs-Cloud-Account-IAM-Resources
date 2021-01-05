# TL;DR
A terraform module that completely replaces the manual [Create and Edit a Cloud Account for Redis Cloud Ultimate](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/) and its subprocess ([Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/)).

# Longer

[Create and Edit a Cloud Account for Redis Cloud Ultimate](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/) shows a manual process for creating a Redis Labs Cloud Account in Subscription Manager. It relies up [Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) which describes a manual process for creating the necessary resources. 

This repo contains a terraform module to automate both of those manual processes, reducing errors and enabling automation.

Should you still require access to the  underlying AWS resources then you can obtain access via `terraform output` - see below for details.

# Basic Use
In the basic use case we need to configure both the providers and the module with the necessary values. We construct a Redis Cloud Account called 'Cloud Account 1234'

See [Redis Enterprise Cloud Provider](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs) and [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for details about configuring the two providers.

See this module's [input](https://registry.terraform.io/modules/TobyHFerguson/Redislabs-Cloud-Account-Resources/aws/latest?tab=inputs) documents for details about configuring this module.

The following is the contents of the `main.tf` file:
```
terraform {
    required_providers {
        rediscloud = {
            source = "RedisLabs/rediscloud"
            version = "0.2.1"
        }
	aws = {
	    source = "hashicorp/aws"
	    version = "3.21.0"
	}
    }
}

provider "aws" {
    profile = "tobyhf-admin"
    region = "us-east-1"
}

provider "rediscloud" {
   api_key = "XXXXXXXX"
   secret_key = "XXXXXX"
}


module "Redislabs-Cloud-Account-Resources" {
    source = "TobyHFerguson/Redislabs-Cloud-Account-Resources/aws"
    pgp_key = "keybase:toby_h_ferguson"
	cloud_account_name = "Cloud Account 1234"

}
```

## Optional Outputs
If we wanted to we could add an `outputs.tf` file to get all the outputs:

```

output "accessKeyId" {
    value = module.Redislabs-Cloud-Account-Resources.accessKeyId
}

output "accessSecretKey" {
    value = module.Redislabs-Cloud-Account-Resources.accessSecretKey
    sensitive = true
}

output "IAMRoleName" {
    value =  module.Redislabs-Cloud-Account-Resources.IAMRoleName
}

output "consoleUsername" {
    value = module.Redislabs-Cloud-Account-Resources.consoleUsername
}

output "signInLoginUrl" {
    description =  "Redis Labs User's console login URL"
    value = module.Redislabs-Cloud-Account-Resources.signInLoginUrl
}

output "consolePassword" {
    value = module.Redislabs-Cloud-Account-Resources.consolePassword
    sensitive = true
}
```

## AWS Resource Details
This module constructs all the resources required to configure a cloud account using one of two approaches. It also configures the cloud account, so these resources are only of marginal interest in normal use, but are included here for completeness.

The two configuration approaches are:
1. By hand, when one will [follow these instructions](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/)
1. By the Cloud API, when one will use [this specific call](https://api.redislabs.com/v1/swagger-ui.html#/Cloud%20Accounts/createCloudAccountUsingPOST)
  
One obtains the values of the resources as terraform outputs. The module shows the values in the 'Outputs' section, except for the secrets (`accessSecretKey` and `consolePassword`), where they are displayed as `<sensitive>`. 

The `accessSecretKey` can be output directly if asked for explicitly:

```
terraform output accessSecretKey
```

The `consolePassword` is base-64 encoded, as well as being encrypted using a pgp key. It can be obtained thus:

```
terraform output consolePassword | tr -d \" | base64 --decode | keybase pgp decrypt
```

The mapping between the stack outputs and the names used in the two different configuration methods is shown below:
  
| Output | By Hand | By API|
|---------|---|---|
| IAMRoleName | IAM Role Name | - |
| accessKeyId | AWS_ACCESS_KEY_ID | accessKeyId |
| accessSecretKey | AWS_SECRET_ACCESS_KEY | accessSecretKey |
| consolePassword | - | consolePassword |
| consoleUsername| - | consoleUsername |
| signInLoginUrl | - | signInLoginUrl |



# Developer Notes
This module includes two policy files, the source of which is currently (Jan 2021) the [Creating IAM Entities for AWS Cloud Accounts](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) page.

Any changes to those policies should cause this module to be updated.

 
 - `RedisLabsIAMUserRestrictedPolicy.json`: Defines restricted access policy for the `redislabs-user`
 - `RedisLabsInstanceRolePolicy.json`: Defines the instance role policy for the instances managed by Redis Labs
 ----------
