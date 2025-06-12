output "pipeline" {
  value = aws_codepipeline.this
}

output "pipeline_role" {
  value = aws_iam_role.codepipeline_role
}

output "codebuild_role" {
  value = aws_iam_role.codebuild
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.this
}

output "bucket" {
  value = aws_s3_bucket.this
}
