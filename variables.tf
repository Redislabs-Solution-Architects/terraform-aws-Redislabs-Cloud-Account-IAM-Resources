variable "pgp_key" {
    type = string
    description = "(Required) Either a base-64 encoded PGP public key, or a [keybase](https://keybase.io/) username in the form `keybase:username`. This user must exist within [keybase](https://keybase.io/)"
}