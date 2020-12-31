output "accessKeyId" {
    description = "The access key id for the redislabs-user"
    value = aws_iam_access_key.RedisLabsUserAccessKey.id
}

output "accessSecretKey" {
    description = "The secret access key for the redislabs-user. *NOTE* The encrypted secret can be decoded on the command line: 'terraform output accessSecretKey | tr -d \" | base64 --decode | keybase pgp decrypt'
    value = aws_iam_access_key.RedisLabsUserAccessKey.encrypted_secret
    sensitive = true
}

output "IAMRoleName" {
    description = "The name of the console role with access to the console"
    value =  aws_iam_role.RedisLabsCrossAccountRole.name
}

output "consoleUsername" {
    description =  "Redis Labs Users login username - redislabs-user"
    value = aws_iam_user.RedisLabsUser.name
}

data "aws_caller_identity" "current" {}

output "signInLoginUrl" {
    description =  "Redis Labs User's console login URL"
    value = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "consolePassword" {
    description = "The redislabs-user's password. *NOTE* The encrypted secret can be decoded on the command line: 'terraform output consolePassword | tr -d \" | base64 --decode | keybase pgp decrypt"'
    value = aws_iam_user_login_profile.RedisLabsUserLoginProfile.encrypted_password
    sensitive = true
}
