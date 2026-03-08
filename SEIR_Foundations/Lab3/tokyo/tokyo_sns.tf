resource "aws_sns_topic" "shinjuku_sns_topic01" {
  name = "${var.shinjuku}-db-incidents"
  provider = aws.tokyo
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "shinjuku_sns_sub01" {
  topic_arn = aws_sns_topic.shinjuku_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
  provider = aws.tokyo
}