
# IAM admin users

resource "aws_iam_user" "admin_users" {
  for_each = toset(var.admin_users)
  name = each.key
  path = "/backups/"
}

resource "aws_iam_user_group_membership" "admin_users" {
  for_each = aws_iam_user.admin_users
  
  user = each.value.name

  groups = [
    aws_iam_group.admin_users.name,
  ]
}

resource "aws_iam_group" "admin_users" {
  name = "admin_users"
  path = "/backups/"
}

resource "aws_iam_group_policy" "admin_users" {
  name   = "admin_users"
  group  = aws_iam_group.admin_users.name
  policy = data.aws_iam_policy_document.admin_users.json
}

data "aws_iam_policy_document" "admin_users" {

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.backups.arn}",
    ]
  }
  
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",      
    ]
    resources = [
      "${aws_s3_bucket.backups.arn}/*",
    ]
  }
}

# IAM backup users

resource "aws_iam_user" "backup_users" {
  for_each = var.backup_users
  name = each.key
  path = "/backups/"
}

resource "aws_iam_user_policy" "backup_users" {
  for_each = aws_iam_user.backup_users

  name   = "backup_users"
  user   = each.value.name
  policy = data.aws_iam_policy_document.backup_users[each.key].json
}

data "aws_iam_policy_document" "backup_users" {
  for_each = var.backup_users

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.backups.arn}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.backups.arn}/repo/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = flatten([
      [ for job in each.value : "${aws_s3_bucket.backups.arn}/jobs/${job}/*" ],
      [ for job in each.value : "${aws_s3_bucket.backups.arn}/manifests/${job}/*" ],
      [ "${aws_s3_bucket.backups.arn}/data/*" ],
    ])
  }
}


# IAM restore users

resource "aws_iam_user" "restore_users" {
  for_each = var.restore_users
  name = each.key
  path = "/backups/"
}

resource "aws_iam_user_policy" "restore_users" {
  for_each = aws_iam_user.restore_users

  name   = "restore_users"
  user   = each.value.name
  policy = data.aws_iam_policy_document.restore_users[each.key].json
}

data "aws_iam_policy_document" "restore_users" {
  for_each = var.restore_users

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.backups.arn}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = flatten([
      [ "${aws_s3_bucket.backups.arn}/repo/*" ],
      [ for job in each.value : "${aws_s3_bucket.backups.arn}/jobs/${job}/*" ],
      [ for job in each.value : "${aws_s3_bucket.backups.arn}/manifests/${job}/*" ],
      [ "${aws_s3_bucket.backups.arn}/data/*" ],
    ])
  }
}


# Credentials and configs for all users

locals {
  all_users = toset(flatten([
    var.admin_users,
    [ for user, _ in var.backup_users : user ],
    [ for user, _ in var.restore_users : user ],
  ]))
}

resource "aws_iam_access_key" "all_users" {
  for_each = local.all_users
  user = each.key
  
  depends_on = [
    aws_iam_user.admin_users,
    aws_iam_user.backup_users,
    aws_iam_user.restore_users,
  ]
}

locals {
  aws_profiles = merge(
    { for u in var.admin_users: u => "s3admin" },
    { for u, _ in var.backup_users: u => "s3backup" },
    { for u, _ in var.restore_users: u => "s3restore" }
  )
}

resource "local_file" "credentials" {
  for_each = aws_iam_access_key.all_users
  
  content = templatefile("templates/credentials.tpl", {
    profile_name      = local.aws_profiles[each.key]
    access_key_id     = each.value.id
    secret_access_key = each.value.secret
  })
  filename        = "local/users/${each.key}/credentials"
  file_permission = "0640"
}

resource "local_file" "configs" {
  for_each = aws_iam_access_key.all_users
  
  content = templatefile("templates/config.tpl", {
    profile_name  = local.aws_profiles[each.key]
    bucket_region = var.aws_region
  })
  filename        = "local/users/${each.key}/config"
  file_permission = "0640"
}