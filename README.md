  # TL;DR
  Automate the [Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) process using Terraform

# Longer

[Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) describes a manual process for creating the necessary resources so that you can subsequently _configure_ an AWS Cloud Account into your Redis Cloud Account, allowing your Redis Cloud Account to create resources in your AWS Cloud Account. This is an error-prone process. (It is also possible to _configure_ an AWS Cloud Account using the API.)

This repo contains a template (`RedisCloud.yaml`) to construct the necessary resources, no matter how whether you want to configure 'By Hand' or 'By API'.

If you configure an AWS Cloud Account by hand you'll be [following these instructions](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/)

If you configure an AWS Cloud Account using the Cloud API you'll use [this specific call](https://api.redislabs.com/v1/swagger-ui.html#/Cloud%20Accounts/createCloudAccountUsingPOST)
  
The template will construct the necessary resources required for both approaches. It will show them in the 'output' section of the stack, except for the secrets (`AWS_SECRET_KEY` and `password`), which are stored as secrets in the AWS Secret's manager. For these secrets the URL is output, from whence one can find the actual secret, assuming one has sufficient permissions.

The mapping between the stack outputs and the names used in the two different configuration methods is shown below:
  
| Output | By Hand | By API|
|---------|---|---|
| IAMRoleName | IAM Role Name | - |
| accessKeyId | AWS_ACCESS_KEY_ID | accessKeyId |
| accessSecretKey | AWS_SECRET_ACCESS_KEY | accessSecretKey |
| consolePassword | - | consolePassword |
| consoleUsername| - | consoleUsername |
| signInLoginUrl | - | signInLoginUrl |

 # Policy files
 Two policy files, which are shared by a Cloudformation version of this mechanism, are stored in s3:
 
 - [RedisLabsIAMUserRestrictedPolicy.json]: Defines restricted access policy for the `redislabs-user`
 - [RedisLabsInstanceRolePolicy.json]: Defines the instance role policy for the instances managed by Redis Labs
 ----------
 
[RedisLabsIAMUserRestrictedPolicy.json]: https://s3.amazonaws.com/cloudformation-templates.redislabs.com/RedisLabsIAMUserRestrictedPolicy.json

[RedisLabsInstanceRolePolicy.json]: https://s3.amazonaws.com/cloudformation-templates.redislabs.com/RedisLabsInstanceRolePolicy.json


