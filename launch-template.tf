locals {
  launch_template_configured = length(var.launch_template_id) == 1
  generate_launch_template   = local.enabled && local.launch_template_configured == false
  fetch_launch_template      = local.enabled && local.launch_template_configured

  launch_template_id = local.enabled ? (local.fetch_launch_template ? var.launch_template_id[0] : aws_launch_template.default[0].id) : ""
  launch_template_version = local.enabled ? (length(var.launch_template_version) == 1 ? var.launch_template_version[0] : (
    local.fetch_launch_template ? data.aws_launch_template.this[0].latest_version : aws_launch_template.default[0].latest_version
  )) : null

  launch_template_ami = length(var.ami_image_id) == 0 ? (local.features_require_ami ? data.aws_ami.selected[0].image_id : "") : var.ami_image_id[0]

  associate_cluster_security_group = local.enabled && var.associate_cluster_security_group
  launch_template_vpc_security_group_ids = sort(compact(concat(
    local.associate_cluster_security_group ? data.aws_eks_cluster.this[*].vpc_config[0].cluster_security_group_id : [],
    module.ssh_access[*].id,
    var.associated_security_group_ids
  )))
}

resource "aws_launch_template" "default" {
  count = local.generate_launch_template ? 1 : 0

  ebs_optimized = var.ebs_optimized

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", null)
        encrypted             = lookup(block_device_mappings.value, "encrypted", null)
        iops                  = lookup(block_device_mappings.value, "iops", null)
        kms_key_id            = lookup(block_device_mappings.value, "kms_key_id", null)
        snapshot_id           = lookup(block_device_mappings.value, "snapshot_id", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        volume_size           = lookup(block_device_mappings.value, "volume_size", null)
        volume_type           = lookup(block_device_mappings.value, "volume_type", null)
      }
    }
  }

  name_prefix            = module.label.id
  update_default_version = true

  # Never include instance type in launch template because it is limited to just one
  # https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateNodegroup.html#API_CreateNodegroup_RequestSyntax
  image_id = local.launch_template_ami == "" ? null : local.launch_template_ami
  key_name = local.ec2_ssh_key_name

  dynamic "tag_specifications" {
    for_each = var.resources_to_tag
    content {
      resource_type = tag_specifications.value
      tags          = local.node_tags
    }
  }
  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required ? "required" : "optional"
  }

  vpc_security_group_ids = local.launch_template_vpc_security_group_ids
  user_data              = local.userdata
  tags                   = local.node_group_tags

  dynamic "placement" {
    for_each = var.placement

    content {
      affinity                = lookup(placement.value, "affinity", null)
      availability_zone       = lookup(placement.value, "availability_zone", null)
      group_name              = lookup(placement.value, "group_name", null)
      host_id                 = lookup(placement.value, "host_id", null)
      host_resource_group_arn = lookup(placement.value, "host_resource_group_arn", null)
      spread_domain           = lookup(placement.value, "spread_domain", null)
      tenancy                 = lookup(placement.value, "tenancy", null)
      partition_number        = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "enclave_options" {
    for_each = var.enclave_enabled ? ["true"] : []

    content {
      enabled = true
    }
  }

  monitoring {
    enabled = var.detailed_monitoring_enabled
  }

}

data "aws_launch_template" "this" {
  count = local.fetch_launch_template ? 1 : 0

  id = var.launch_template_id[0]
}
