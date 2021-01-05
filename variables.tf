variable "pgp_key" {
    type = string
    description = "(Required) Either a base-64 encoded PGP public key, or a keybase (see https://keybase.io/) username in the form 'keybase:username'. This user must exist within keybase"
}

variable "cloud_account_name" {
    type = string
    description = "(Required) The name to be assigned to the Cloud Account in RedisLabs Subscription Manager"
}
