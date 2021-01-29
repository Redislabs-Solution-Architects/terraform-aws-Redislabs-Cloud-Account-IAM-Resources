# TL;DR
  Automate the manual [Creating IAM Entities for AWS Cloud Accounts](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) process by using Terraform.

A PGP key is required. See the variable `pgp_key` for details.

# Longer

[Creating IAM Entities for AWS Cloud Accounts](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) describes a manual process for creating the necessary IAM entities so that you can subsequently _configure_ an AWS Cloud Account into your Redis Cloud Account, allowing your Redis Cloud Account the necessary access to your AWS Cloud Account.

This repo contains a terraform module to construct the necessary IAM entities.

The template will construct the necessary IAM entities required for both approaches. You can display the values using `terraform output` except for the secrets (`accessSecretKey` and `consolePassword`), where they are displayed as `<sensitive>`. The actual values of those secrets can be obtained thus:

* accessSecretKey: `terraform output accessSecretKey`
* consolePassword: `
terraform output consolePassword | tr -d \" | base64 --decode | keybase pgp decrypt
`

There are two different methods for configuring the AWS Cloud account:

* By Hand: you'll be [following these instructions](https://docs.redislabs.com/latest/rc/how-to/view-edit-cloud-account/)

* By API: you'll use [this specific call](https://api.redislabs.com/v1/swagger-ui.html#/Cloud%20Accounts/createCloudAccountUsingPOST)

The mapping between the terraform outputs and the names used in the two different configuration methods is shown below:

| Output          | By Hand               | By API          |
|-----------------|-----------------------|-----------------|
| IAMRoleName     | IAM Role Name         | _unused_        |
| accessKeyId     | AWS_ACCESS_KEY_ID     | accessKeyId     |
| accessSecretKey | AWS_SECRET_ACCESS_KEY | accessSecretKey |
| consolePassword | _unused_              | consolePassword |
| consoleUsername | _unused_              | consoleUsername |
| signInLoginUrl  | _unused_              | signInLoginUrl  |

Note that each approach has a slightly different set of values required than the other.

# Example Terraform
## Basic IAM Entity Construction

The following terraform template will create the necessary resources, and output all the resource information. You would then use this information to configure the Cloud Account using the By Hand or By API methods. Further ideas for automation are shown in subsequent examples.

This example uses my keybase key (toby_h_ferguson), which you might wish to replace with your own key.

I also include some example configurations for the aws provider, which you'll have to modify to suit your environment.

It is useful if we split this between three files:

* `provider.tf`: contains the provider details
* `module.tf`: contains the instantiation of the `Redislabs-Cloud-Account-Resources` module
* `outputs.tf`: contains the outputs from our example.

### `provider.tf`
Setup the aws provider needed by this module:
```terraform
provider "aws" {
    profile = "tobyhf-admin"
    region = "us-east-1"
}
```

### `module.tf`
Setup the use of this module, configuring it with the required `pgp_key` by which the `consolePassword` is encrypted:

```
module "Redislabs-Cloud-Account-Resources" {
    source = "TobyHFerguson/Redislabs-Cloud-Account-Resources/aws"
    pgp_key = "keybase:toby_h_ferguson"
}
```

### `outputs.tf`
Make the outputs easier to access:

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

## Redis Labs Cloud Account Creation via Terraform
To automate cloud account creation completely one would add the `RedisLabs/rediscloud` provider, configure it, and then take the necessary parts to create the managed cloud account, dropping `outputs.tf` above since those values are used in to create the cloud account and aren't needed to be output.

This would create the cloud account resource which one could access via the [`rediscloud_cloud_account` data resource](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs/data-sources/rediscloud_cloud_account), filtering on the given name (which just happens to be `Tobys TF Account - 2` in this example).


From a file perspective we'll have:

* `provider.tf`: extended to include the `Redislabs/rediscloud` provider
* `module.tf`: (unchanged) instantiates the `Redislabs-Cloud-Account-Resources` module
* `cloud_account.tf`: create a cloud account resource

`output.tf` is deleted.

### `provider.tf`
We extend the providers to include `Redislabs/rediscloud`, and configure with the required cloud api key and secret key:

```terraform
provider "aws" {
    profile = "tobyhf-admin"
    region = "us-east-1"
}

terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
      version = "0.2.1"
    }
  }
}

provider "rediscloud" {
  api_key = "XXXX"
  secret_key = "XXXX"
}

```

### `module.tf`
Unchanged:
```
module "Redislabs-Cloud-Account-Resources" {
    source = "TobyHFerguson/Redislabs-Cloud-Account-Resources/aws"
    pgp_key = "keybase:toby_h_ferguson"
}
```

### `cloud_account.tf`
We add the creation of the `rediscloud_cloud_account` resource, which is the key purpose of this example:

```
resource "rediscloud_cloud_account" "example" {
  depends_on = [time_sleep.delay]
  access_key_id     = module.Redislabs-Cloud-Account-Resources.accessKeyId
  access_secret_key = module.Redislabs-Cloud-Account-Resources.accessSecretKey
  console_username  = module.Redislabs-Cloud-Account-Resources.consoleUsername
  console_password  = module.Redislabs-Cloud-Account-Resources.consolePassword
  name              = "Tobys TF Account - 2"
  provider_type     = "AWS"
  sign_in_login_url = module.Redislabs-Cloud-Account-Resources.signInLoginUrl
}

resource "time_sleep" "delay" {
  create_duration = "15s"
}

```
Note the use of the `time_sleep` resource. It turns out that one or more of the IAM Entities aren't fully setup by the time the `Redislabs-Cloud-Account-Resources` module is finished and omitting this timeout will result in the following error message:

```
Error: 400 BAD_REQUEST - CLOUD_ACCOUNT_INVALID_CREDS: Invalid credentials provided
```

We've found that this timeout varies - 15s seems OK, but we've got it as low as 8s and then its had to be raised up again. You might need to adjust it for your environment.

## Subscription Creation via Terraform
You might want to create and destroy all of the resources including a subscription (and its required database) in one Terraform template. This example shows you how to do that.

However we feel that this is an unlikely scenario - the lifecycle of the cloud account resource is typically quite different from that of databases and subscriptions. However we include it here for completeness (and because it exposes a hidden dependency, which is interesting and must be accounted for!)

From a file perspective we have:
* `provider.tf`: unchanged
* `module.tf`: unchanged
* `cloud_account.tf`: minor change to ensure deletion occurs correctly
* `subscription.tf`: new file that describes the subscription and database resources we want created
* `output.tf` - outputs the database endpoint and password needed to connect

### `provider.tf`
This is unchanged from the previous example:

```terraform
provider "aws" {
    profile = "tobyhf-admin"
    region = "us-east-1"
}

terraform {
  required_providers {
    rediscloud = {
      source = "RedisLabs/rediscloud"
      version = "0.2.1"
    }
  }
}

provider "rediscloud" {
  api_key = "XXXX"
  secret_key = "XXXX"
}

```

### `module.tf`
Unchanged:
```
module "Redislabs-Cloud-Account-Resources" {
    source = "TobyHFerguson/Redislabs-Cloud-Account-Resources/aws"
}
```

### `cloud_account.tf`
It turns out that the `Redislabs-Cloud-Account-Resources` module creates some resources (e.g. policies, roles etc.) that aren't directly referenced by the subscription or cloud account resources. Nevertheless they can't be destroyed before either the subscription or cloud account resources. We therefore need to add the entire module to the `depends_on` clause to prevent deletion of these otherwise hidden resources:
```
resource "rediscloud_cloud_account" "example" {
  depends_on = [time_sleep.delay, module.Redislabs-Cloud-Account-Resources]
  access_key_id     = module.Redislabs-Cloud-Account-Resources.accessKeyId
  access_secret_key = module.Redislabs-Cloud-Account-Resources.accessSecretKey
  console_username  = module.Redislabs-Cloud-Account-Resources.consoleUsername
  console_password  = module.Redislabs-Cloud-Account-Resources.consolePassword
  name              = "Tobys TF Account - 2"
  provider_type     = "AWS"
  sign_in_login_url = module.Redislabs-Cloud-Account-Resources.signInLoginUrl
}

resource "time_sleep" "delay" {
  create_duration = "15s"
}
```

### `subscription.tf`
This is the file in which we describe the subscription and database resources we want to create.

In this example we *must* define some payment method, and that payment method must be unique, hence the filtering in the example below.

```
data "rediscloud_payment_method" "card" {
    card_type = "Visa"
    last_four_numbers = "1111"
}

resource "random_password" "password" {
  length = 20
  upper = true
  lower = true
  number = true
  special = false
}

resource "rediscloud_subscription" "toby-test-2" {
  name = "tobys-test-2"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage = "ram"

  cloud_provider {
    provider = rediscloud_cloud_account.example.provider_type
    cloud_account_id = rediscloud_cloud_account.example.id
    region {
      region = "eu-west-1"
      networking_deployment_cidr = "10.0.0.0/24"
      preferred_availability_zones = ["eu-west-1a"]
    }
  }

  database {
    name = "tf-example-database"
    protocol = "redis"
    memory_limit_in_gb = 1
    data_persistence = "none"
    throughput_measurement_by = "operations-per-second"
    throughput_measurement_value = 10000
    password = random_password.password.result

    alert {
      name = "dataset-size"
      value = 40
    }
  }
}
```

### `output.tf`
Here we provide the database endpoints and password used

```
output "database_endpoints" {
  value = {
    for database in rediscloud_subscription.toby-test-2.database:
      database.name => database.public_endpoint
  }
}

output "database_password" {
  value = random_password.password.result
}
```

###

# Error Messages

## `Error: 400 BAD_REQUEST - CLOUD_ACCOUNT_INVALID_CREDS: Invalid credentials provided`

This occurs when the `Redislabs-Cloud-Account-Resources` module hasn't been given sufficient time for its AWS resources to be created before being accessed. You need to extend the timeout.

## `Error: failed to cloud account: 401 - "Authentication error: Authentication failed for provided credentials"`
This occurs when you haven't provided the correct credentials (`api` and `secret`) to the `rediscloud` provider



# Developer Notes
This module includes two policy files, the source of which is currently (Jan 2021) the [Creating IAM Entities for AWS Cloud Accounts](https://docs.redislabs.com/latest/rc/how-to/creating-aws-user-redis-enterprise-vpc/) page.

Any changes to those policies should cause this module to be updated.

- `RedisLabsIAMUserRestrictedPolicy.json`: Defines restricted access policy for the `redislabs-user`
 - `RedisLabsInstanceRolePolicy.json`: Defines the instance role policy for the instances managed by Redis Labs
 ----------
