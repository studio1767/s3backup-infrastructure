
resource "aws_s3_object" "jobs" {
  for_each = local.backup_jobs
  
  bucket = aws_s3_bucket.backups.id
  key = "jobs/${each.key}/${each.key}-000.yml"
  content = file("templates/job.yml")
}

