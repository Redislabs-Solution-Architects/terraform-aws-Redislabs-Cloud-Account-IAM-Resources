# TL;DR
  Automate the manual [Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) process by using Terraform.

A PGP key is required. See the variable `pgp_key` for details.

# Longer

[Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) describes a manual process for creating the necessary resources so that you can subsequently _configure_ an AWS Cloud Account into your Redis Cloud Account, allowing your Redis Cloud Account to create resources in your AWS Cloud Account. 

This repo contains a terraform module to construct the necessary IAM resources.

If you configure an AWS Cloud Account by hand you'll be [following these instructions](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/)

If you configure an AWS Cloud Account using the Cloud API you'll use [this specific call](https://api.redislabs.com/v1/swagger-ui.html#/Cloud%20Accounts/createCloudAccountUsingPOST)
  
The template will construct the necessary IAM resources required for both approaches. It will show the values in the 'Outputs' section of the stack, except for the secrets (`accessSecretKey` and `consolePassword`), where they are displayed as `<sensitive>`. The actual values of those secrets can be obtained using the general formula:

```
terraform output OUTPUT_VARIABLE | tr -d \" | base64 --decode | keybase pgp decrypt
```

where OUTPUT_VARIABLE is either `accessSecretKey` or `consolePassword`

The mapping between the stack outputs and the names used in the two different configuration methods is shown below:
  
| Output | By Hand | By API|
|---------|---|---|
| IAMRoleName | IAM Role Name | - |
| accessKeyId | AWS_ACCESS_KEY_ID | accessKeyId |
| accessSecretKey | AWS_SECRET_ACCESS_KEY | accessSecretKey |
| consolePassword | - | consolePassword |
| consoleUsername| - | consoleUsername |
| signInLoginUrl | - | signInLoginUrl |

# Developers
This module includes two policy files, the source of which is currently (Jan 2021) the [Creating IAM Entities for AWS Cloud Accounts](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) page.

Any changes to those policies should cause this module to be updated.

 
 - `RedisLabsIAMUserRestrictedPolicy.json`: Defines restricted access policy for the `redislabs-user`
 - `RedisLabsInstanceRolePolicy.json`: Defines the instance role policy for the instances managed by Redis Labs
 ----------
