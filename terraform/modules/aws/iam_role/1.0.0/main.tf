resource "aws_iam_role" "role" {
  name = var.role_name

  assume_role_policy = var.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each = { for idx, policy_attachment_arn in var.policy_attachment_arns : idx => policy_attachment_arn }

  policy_arn = each.value
  role       = aws_iam_role.role.name
}
