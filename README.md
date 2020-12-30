  # TL;DR
  Automate the [Creating IAM Entities for AWS Cloud Accounts 
](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) process using the following Cloudformation stack template:
  
  <a href="https://console.aws.amazon.com/cloudformation/home?#/stacks/new?stackName=RedisCloud&templateURL=https://s3.amazonaws.com/cloudformation-templates.redislabs.com/RedisCloud.yaml">
<img alt="Launch RedisCloud template" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"/>
</a>

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

 # S3 Location
 The cloudformation template is stored in the publicly accessible Redislabs owned bucket at: `cloudformation-templates.redislabs.com/RedisCloud.yaml`

Copy the template to the bucket thus (assuming the AWS profile `redislabs`):

```
aws s3 --profile redislabs cp RedisCloud.yaml s3://cloudformation-templates.redislabs.com
```
