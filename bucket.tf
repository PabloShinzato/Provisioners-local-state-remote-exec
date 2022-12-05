resource "aws_s3_bucket" "first_bucket" {
  bucket = "pablo-shinzato-codercrypt-remote-state"

  tags = local.common_tags
}
