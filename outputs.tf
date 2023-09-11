output "eks_node_group_role_arn" {
  value       = join("", aws_iam_role.default[*].arn)
}

output "eks_node_group_role_name" {
  value       = join("", aws_iam_role.default[*].name)
}

output "eks_node_group_id" {
  value       = join("", aws_eks_node_group.default[*].id, aws_eks_node_group.cbd[*].id)
}

output "eks_node_group_arn" {
  value       = join("", aws_eks_node_group.default[*].arn, aws_eks_node_group.cbd[*].arn)
}

output "eks_node_group_resources" {
  value       = local.enabled ? (var.create_before_destroy ? aws_eks_node_group.cbd[*].resources : aws_eks_node_group.default[*].resources) : []
}

output "eks_node_group_status" {
  value       = join("", aws_eks_node_group.default[*].status, aws_eks_node_group.cbd[*].status)
}

output "eks_node_group_remote_access_security_group_id" {
  value       = join("", module.ssh_access[*].id)
}

output "eks_node_group_cbd_pet_name" {
  value       = join("", random_pet.cbd[*].id)
}

output "eks_node_group_launch_template_id" {
  value       = local.launch_template_id
}

output "eks_node_group_launch_template_name" {
  value       = local.enabled ? (local.fetch_launch_template ? join("", data.aws_launch_template.this[*].name) : join("", aws_launch_template.default[*].name)) : null
}

output "eks_node_group_tags_all" {
  value       = local.enabled ? (var.create_before_destroy ? aws_eks_node_group.cbd[0].tags_all : aws_eks_node_group.default[0].tags_all) : {}
}

output "eks_node_group_windows_note" {
  value       = local.enabled && local.is_windows && local.need_bootstrap ? "When specifying a custom AMI ID for Windows managed node groups, add eks:kube-proxy-windows to your AWS IAM Authenticator configuration map. For more information, see Limits and conditions when specifying an AMI ID. https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html" : ""
}
