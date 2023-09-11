locals {
  enabled = module.this.enabled

  features_require_ami = local.enabled && local.need_bootstrap
  need_ami_id          = local.enabled ? local.features_require_ami && length(var.ami_image_id) == 0 : false

  have_ssh_key     = local.enabled && length(var.ec2_ssh_key_name) == 1
  ec2_ssh_key_name = local.have_ssh_key ? var.ec2_ssh_key_name[0] : null

  need_ssh_access_sg = local.enabled && (local.have_ssh_key || length(var.ssh_access_security_group_ids) > 0) && local.generate_launch_template

  get_cluster_data = local.enabled ? (local.need_cluster_kubernetes_version || local.need_bootstrap || local.need_ssh_access_sg || length(var.associated_security_group_ids) > 0) : false

  taint_effect_map = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  autoscaler_enabled = var.cluster_autoscaler_enabled
  autoscaler_enabled_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
  }
  autoscaler_kubernetes_label_tags = {
    for label, value in var.kubernetes_labels : format("k8s.io/cluster-autoscaler/node-template/label/%v", label) => value
  }
  autoscaler_kubernetes_taints_tags = {
    for taint in var.kubernetes_taints : format("k8s.io/cluster-autoscaler/node-template/taint/%v", taint.key) =>
    "${taint.value == null ? "" : taint.value}:${local.taint_effect_map[taint.effect]}"
  }
  autoscaler_tags = merge(local.autoscaler_enabled_tags, local.autoscaler_kubernetes_label_tags, local.autoscaler_kubernetes_taints_tags)

  node_tags = merge(
    module.label.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
  node_group_tags = merge(local.node_tags, local.autoscaler_enabled ? local.autoscaler_tags : null)

  windows_taint = [{
    key    = "OS"
    value  = "Windows"
    effect = "NO_SCHEDULE"
  }]
}

module "label" {
  source  = "git::https://github.com/socratesdao/tf-module-null-label"

  attributes = ["workers"]

  context = module.this.context
}

data "aws_eks_cluster" "this" {
  count = local.get_cluster_data ? 1 : 0
  name  = var.cluster_name
}

locals {
  is_windows = can(regex("WINDOWS", var.ami_type))
  ng = {
    cluster_name  = var.cluster_name
    node_role_arn = local.create_role ? join("", aws_iam_role.default[*].arn) : try(var.node_role_arn[0], null)

    subnet_ids = sort(var.subnet_ids)

    instance_types = sort(var.instance_types)
    ami_type       = local.launch_template_ami == "" ? var.ami_type : null
    capacity_type  = var.capacity_type
    labels         = var.kubernetes_labels == null ? {} : var.kubernetes_labels

    taints          = local.is_windows ? concat(local.windows_taint, var.kubernetes_taints) : var.kubernetes_taints
    release_version = local.launch_template_ami == "" ? try(var.ami_release_version[0], null) : null
    version         = length(compact(concat([local.launch_template_ami], var.ami_release_version))) == 0 ? try(var.kubernetes_version[0], null) : null

    tags = local.node_group_tags

    scaling_config = {
      desired_size = var.desired_size
      max_size     = var.max_size
      min_size     = var.min_size
    }
  }
}

resource "random_pet" "cbd" {
  count = local.enabled && var.create_before_destroy ? 1 : 0

  separator = module.label.delimiter
  length    = 1

  keepers = {
    node_role_arn  = local.ng.node_role_arn
    subnet_ids     = join(",", local.ng.subnet_ids)
    instance_types = join(",", local.ng.instance_types)
    ami_type       = local.ng.ami_type
    capacity_type  = local.ng.capacity_type

    launch_template_id = local.launch_template_id
  }
}

resource "aws_eks_node_group" "default" {
  count           = local.enabled && !var.create_before_destroy ? 1 : 0
  node_group_name = module.label.id

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [scaling_config[0].desired_size]
  }

  cluster_name    = local.ng.cluster_name
  node_role_arn   = local.ng.node_role_arn
  subnet_ids      = local.ng.subnet_ids
  instance_types  = local.ng.instance_types
  ami_type        = local.ng.ami_type
  labels          = local.ng.labels
  release_version = local.ng.release_version
  version         = local.ng.version

  capacity_type = local.ng.capacity_type

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  launch_template {
    id      = local.launch_template_id
    version = local.launch_template_version
  }

  dynamic "update_config" {
    for_each = var.update_config

    content {
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
    }
  }

  dynamic "taint" {
    for_each = var.kubernetes_taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  dynamic "timeouts" {
    for_each = var.node_group_terraform_timeouts
    content {
      create = timeouts.value["create"]
      update = timeouts.value["update"]
      delete = timeouts.value["delete"]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.ipv6_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.existing_policies_for_eks_workers_role,
    aws_launch_template.default,
    module.ssh_access,
    var.module_depends_on
  ]
}

resource "aws_eks_node_group" "cbd" {
  count           = local.enabled && var.create_before_destroy ? 1 : 0
  node_group_name = format("%v%v%v", module.label.id, module.label.delimiter, join("", random_pet.cbd[*].id))

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }

  cluster_name    = local.ng.cluster_name
  node_role_arn   = local.ng.node_role_arn
  subnet_ids      = local.ng.subnet_ids
  instance_types  = local.ng.instance_types
  ami_type        = local.ng.ami_type
  labels          = local.ng.labels
  release_version = local.ng.release_version
  version         = local.ng.version

  capacity_type = local.ng.capacity_type

  tags = local.ng.tags

  scaling_config {
    desired_size = local.ng.scaling_config.desired_size
    max_size     = local.ng.scaling_config.max_size
    min_size     = local.ng.scaling_config.min_size
  }

  launch_template {
    id      = local.launch_template_id
    version = local.launch_template_version
  }

  dynamic "update_config" {
    for_each = var.update_config

    content {
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
    }
  }

  dynamic "taint" {
    for_each = var.kubernetes_taints
    content {
      key    = taint.value["key"]
      value  = taint.value["value"]
      effect = taint.value["effect"]
    }
  }

  dynamic "timeouts" {
    for_each = var.node_group_terraform_timeouts
    content {
      create = timeouts.value["create"]
      update = timeouts.value["update"]
      delete = timeouts.value["delete"]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.ipv6_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_launch_template.default,
    module.ssh_access,
    var.module_depends_on
  ]
}
