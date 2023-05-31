
# This is pretty (very) hacky... but using 'external' generates new keys 
# each apply and that's not what we want. 
# I guess that eventually someone will write a terraform provider to
# generate these keys... at which time, this hack can be removed.

resource "null_resource" "age_identity" {
  provisioner "local-exec" {
    command = "mkdir -p local/keys && rm -f local/keys/identity.txt && age-keygen -o local/keys/identities.txt"
  }
}

resource "null_resource" "age_recipient" {
  provisioner "local-exec" {
    command = "rm -f local/keys/recipient.txt && age-keygen -y -o local/keys/recipients.txt local/keys/identities.txt "
  }
  
  depends_on = [
    null_resource.age_identity
  ]
}

resource "aws_s3_object" "recipient" {
  bucket = aws_s3_bucket.backups.id
  key = "repo/recipients.txt"
  source = "local/keys/recipients.txt"
  
  depends_on = [
    null_resource.age_recipient
  ]
}

locals {
  subusers = { for user in local.all_users : user => [ for x in [0, 1, 2, 3] : format("%s-%02d", user, x) ]}
  subuserlist = toset(flatten([ for _, subs in local.subusers : [ for s in subs : s ]]))
  
  wordlist = toset([ for token in split("\n", file("data/bip39-wordlist.txt")) : token if trim(token, " ") != "" ])
}

resource "random_shuffle" "passphrases" {
  for_each = local.subuserlist
  
  input = local.wordlist
  result_count = 10
}

resource "random_string" "passids" {
  for_each = local.subuserlist

  length  = 16
  special = false
}

locals {
  passphrases = {
    for user in local.all_users : user => [
      for subuser in local.subusers[user] : {
        "id" = random_string.passids[subuser].result,
        "pass" = join("-", random_shuffle.passphrases[subuser].result),
      }
    ]
  }
}

resource "local_file" "secrets" {
  for_each = local.all_users
  
  content = templatefile("templates/secrets.yml.tpl", {
    user    = each.key
    secrets = local.passphrases[each.key]
  })
  filename        = "local/users/${each.key}/secrets.yml"
  file_permission = "0640"
}

resource "local_file" "all_secrets" {
  content = templatefile("templates/all-secrets.yml.tpl", {
    all_secrets = local.passphrases
  })
  filename        = "local/keys/all-secrets.yml"
  file_permission = "0640"
}
