
locals {
  arch_label_map = {
    AL2_x86_64                 = "",
    AL2_x86_64_GPU             = "-gpu",
    AL2_ARM_64                 = "-arm64",
    BOTTLEROCKET_x86_64        = "x86_64",
    BOTTLEROCKET_ARM_64        = "aarch64"
    BOTTLEROCKET_ARM_64_NVIDIA = "-gpu"
    BOTTLEROCKET_x86_64_NVIDIA = "-gpu"
    WINDOWS_CORE_2019_x86_64   = ""
    WINDOWS_FULL_2019_x86_64   = ""
    WINDOWS_CORE_2022_x86_64   = ""
    WINDOWS_FULL_2022_x86_64   = ""
  }

  ami_kind = split("_", var.ami_type)[0] != "WINDOWS" ? split("_", var.ami_type)[0] : format("WINDOWS_%s_%s", split("_", var.ami_type)[1], split("_", var.ami_type)[2])

  ami_format = {
    AL2 = "amazon-eks%s-node-%s"
    BOTTLEROCKET = "bottlerocket-aws-k8s-%s-%s-%s"
    WINDOWS_CORE_2019 = "Windows_Server-2019-English-Core-EKS_Optimized-%s-%s"
    WINDOWS_FULL_2019 = "Windows_Server-2019-English-Full-EKS_Optimized-%s-%s"
    WINDOWS_CORE_2022 = "Windows_Server-2022-English-Core-EKS_Optimized-%s-%s"
    WINDOWS_FULL_2022 = "Windows_Server-2022-English-Full-EKS_Optimized-%s-%s"
  }

  need_cluster_kubernetes_version = local.enabled ? local.need_ami_id && length(var.kubernetes_version) == 0 : false

  use_cluster_kubernetes_version = local.need_cluster_kubernetes_version && (local.ami_kind == "BOTTLEROCKET" || length(var.ami_release_version) == 0)

  ami_kubernetes_version = local.need_ami_id ? (local.use_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version :
    regex("^(\\d+\\.\\d+)", coalesce(local.ami_kind == "AL2" ? try(var.ami_release_version[0], null) : null, try(var.kubernetes_version[0], null)))[0]
  ) : ""

  ami_version_regex = local.need_ami_id ? {
    AL2 = (length(var.ami_release_version) == 1 ? replace(var.ami_release_version[0], "/^(\\d+\\.\\d+)\\.\\d+-(\\d+)$/", "$1-v$2") : "${local.ami_kubernetes_version}-*"),
    BOTTLEROCKET      = (length(var.ami_release_version) == 1 ? format("v%s", var.ami_release_version[0]) : "*"),
    WINDOWS_CORE_2019 = (length(var.ami_release_version) == 1 ? format("%s", var.ami_release_version[0]) : "*"),
    WINDOWS_FULL_2019 = (length(var.ami_release_version) == 1 ? format("%s", var.ami_release_version[0]) : "*"),
    WINDOWS_CORE_2022 = (length(var.ami_release_version) == 1 ? format("%s", var.ami_release_version[0]) : "*"),
    WINDOWS_FULL_2022 = (length(var.ami_release_version) == 1 ? format("%s", var.ami_release_version[0]) : "*"),
  } : {}

  ami_regex = local.need_ami_id ? {
    AL2               = format(local.ami_format["AL2"], local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_kind]),
    BOTTLEROCKET      = format(local.ami_format["BOTTLEROCKET"], local.ami_kubernetes_version, local.arch_label_map[var.ami_type], local.ami_version_regex[local.ami_kind]),
    WINDOWS_CORE_2019 = format(local.ami_format["WINDOWS_CORE_2019"], local.ami_kubernetes_version, local.ami_version_regex[local.ami_kind]),
    WINDOWS_FULL_2019 = format(local.ami_format["WINDOWS_FULL_2019"], local.ami_kubernetes_version, local.ami_version_regex[local.ami_kind]),
    WINDOWS_CORE_2022 = format(local.ami_format["WINDOWS_CORE_2022"], local.ami_kubernetes_version, local.ami_version_regex[local.ami_kind]),
    WINDOWS_FULL_2022 = format(local.ami_format["WINDOWS_FULL_2022"], local.ami_kubernetes_version, local.ami_version_regex[local.ami_kind]),
  } : {}
}

data "aws_ami" "selected" {
  count = local.enabled && local.need_ami_id ? 1 : 0

  most_recent = true
  name_regex  = local.ami_regex[local.ami_kind]

  owners = ["amazon"]
}
