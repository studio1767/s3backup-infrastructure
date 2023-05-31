
variable "bucket_name" {
  default = ""
}

variable "admin_users" {
  type = list(string)
  default = [
    "bu_admin1",
    "bu_admin2"
  ]
}

variable "backup_users" {
  type = map(list(string))
  default = {
    bu_user1 = [ "job1" ]
    bu_user2 = [ "job2a", "job2b" ]
  }
}

variable "restore_users" {
  type = map(list(string))
  default = {
    re_user1 = ["job1", "job2a", "job2b"]
    re_user2 = ["job2a", "job2b"]
  }
}

locals {
  backup_jobs = toset(flatten([
    [ for _, jobs in var.backup_users : jobs ],
    [ for _, jobs in var.restore_users : jobs ],
  ]))
}

## AWS settings

variable "aws_profile" {
  default = ""
}

variable "aws_region" {
  default = ""
}

