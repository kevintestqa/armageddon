############################################
# Lab 2B-Honors+ - Optional invalidation action (run on demand)
############################################

# Kevin - Will comment this back in when its time for lab 2B.  Erro to resolve is: lab2b_honors_plus_invalidation_action.tf line 6, in resource "aws_cloudfront_create_invalidation" "chewbacca_invalidate_index01":
# │    6: resource "aws_cloudfront_create_invalidation" "chewbacca_invalidate_index01" {
# │ 
# │ The provider hashicorp/aws does not support resource type "aws_cloudfront_create_invalidation".

# Explanation: This is Chewbacca’s “break glass” lever — use it sparingly or the bill will bite.
# resource "aws_cloudfront_create_invalidation" "chewbacca_invalidate_index01" {
#   distribution_id = aws_cloudfront_distribution.chewbacca_cf01.id

#   # TODO: students must pick the smallest path set that fixes the issue.
#   paths = [
#     "/static/index.html"
#   ]
# }


