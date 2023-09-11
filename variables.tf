variable "cluster_name" {
  type        = string
}

variable "create_before_destroy" {
  type        = bool
  default     = false
}

variable "cluster_autoscaler_enabled" {
  type        = bool
  default     = false
}

variable "ec2_ssh_key_name" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.ec2_ssh_key_name) < 2
    )
    error_message = "You may not specify more than one `ec2_ssh_key_name`."
  }
}

variable "ssh_access_security_group_ids" {
  type        = list(string)
  default     = []
}

variable "desired_size" {
  type        = number
}

variable "max_size" {
  type        = number
}

variable "min_size" {
  type        = number
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
  validation {
    condition = (
      length(var.subnet_ids) > 0
    )
    error_message = "You must specify at least 1 subnet to launch resources in."
  }
}

variable "associate_cluster_security_group" {
  type        = bool
  default     = true
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
}

variable "node_role_cni_policy_enabled" {
  type        = bool
  default     = true
}

variable "node_role_arn" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.node_role_arn) < 2
    )
    error_message = "You may not specify more than one `node_role_arn`."
  }
}

variable "node_role_policy_arns" {
  type        = list(string)
  default     = []
}

variable "node_role_permissions_boundary" {
  type        = string
  default     = null
}

variable "ami_type" {
  type        = string
  default     = "AL2_x86_64"
  validation {
    condition = (
      contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64", "BOTTLEROCKET_ARM_64_NVIDIA", "BOTTLEROCKET_x86_64_NVIDIA", "WINDOWS_CORE_2019_x86_64", "WINDOWS_FULL_2019_x86_64", "WINDOWS_CORE_2022_x86_64", "WINDOWS_FULL_2022_x86_64"], var.ami_type)
    )
    error_message = "Var ami_type must be one of \"AL2_x86_64\",\"AL2_x86_64_GPU\",\"AL2_ARM_64\",\"BOTTLEROCKET_ARM_64\",\"BOTTLEROCKET_x86_64\",\"BOTTLEROCKET_ARM_64_NVIDIA\",\"BOTTLEROCKET_x86_64_NVIDIA\",\"WINDOWS_CORE_2019_x86_64\",\"WINDOWS_FULL_2019_x86_64\",\"WINDOWS_CORE_2022_x86_64\",\"WINDOWS_FULL_2022_x86_64\", or \"CUSTOM\"."
  }
}

variable "instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  validation {
    condition = (
      length(var.instance_types) <= 20
    )
    error_message = "Per the EKS API, no more than 20 instance types may be specified."
  }
}

variable "capacity_type" {
  type        = string
  default     = null
  validation {
    condition     = var.capacity_type == null ? true : contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either `null`, \"ON_DEMAND\", or \"SPOT\"."
  }
}

variable "block_device_mappings" {
  type        = list(any)
  default = [{
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
    encrypted             = true
    delete_on_termination = true
  }]
}

variable "update_config" {
  type        = list(map(number))
  default     = []
}

variable "kubernetes_labels" {
  type        = map(string)
  default     = {}
}

variable "kubernetes_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
}

variable "kubelet_additional_options" {
  type        = list(string)
  default     = []
  validation {
    condition = (length(compact(var.kubelet_additional_options)) == 0 ? true :
      length(regexall("--node-labels", join(" ", var.kubelet_additional_options))) == 0 &&
      length(regexall("--node-taints", join(" ", var.kubelet_additional_options))) == 0
    )
    error_message = "Var kubelet_additional_options must not contain \"--node-labels\" or \"--node-taints\".  Use `kubernetes_labels` and `kubernetes_taints` to specify labels and taints."
  }
}

variable "ami_image_id" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.ami_image_id) < 2
    )
    error_message = "You may not specify more than one `ami_image_id`."
  }
}

variable "ami_release_version" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.ami_release_version) == 0 ? true : length(regexall("(^\\d+\\.\\d+\\.\\d+-[\\da-z]+$)|(^\\d+\\.\\d+\\.\\d+$)", var.ami_release_version[0])) == 1
    )
    error_message = "Var ami_release_version, if supplied, must be like for AL2 \"1.16.13-20200821\" or for bottlerocket \"1.2.0-ccf1b754\" (no \"v\") or for Windows \"2023.02.14\"."
  }
}

variable "kubernetes_version" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.kubernetes_version) == 0 ? true : length(regexall("^\\d+\\.\\d+$", var.kubernetes_version[0])) == 1
    )
    error_message = "Var kubernetes_version, if supplied, must be like \"1.16\" (no patch level)."
  }
}

variable "module_depends_on" {
  type        = any
  default     = null
}

variable "ebs_optimized" {
  type        = bool
  default     = true
}

variable "launch_template_id" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.launch_template_id) < 2
    )
    error_message = "You may not specify more than one `launch_template_id`."
  }
}

variable "launch_template_version" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.launch_template_version) < 2
    )
    error_message = "You may not specify more than one `launch_template_version`."
  }
}

variable "resources_to_tag" {
  type        = list(string)
  default     = ["instance", "volume", "network-interface"]
  validation {
    condition = (
      length(compact([for r in var.resources_to_tag : r if !contains(["instance", "volume", "elastic-gpu", "spot-instances-request", "network-interface"], r)])) == 0
    )
    error_message = "Invalid resource type in `resources_to_tag`. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\", \"network-interface\"."
  }
}

variable "before_cluster_joining_userdata" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.before_cluster_joining_userdata) < 2
    )
    error_message = "You may not specify more than one `before_cluster_joining_userdata`."
  }
}

variable "after_cluster_joining_userdata" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.after_cluster_joining_userdata) < 2
    )
    error_message = "You may not specify more than one `after_cluster_joining_userdata`."
  }
}

variable "bootstrap_additional_options" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.bootstrap_additional_options) < 2
    )
    error_message = "You may not specify more than one `bootstrap_additional_options`."
  }
}

variable "userdata_override_base64" {
  type        = list(string)
  default     = []
  validation {
    condition = (
      length(var.userdata_override_base64) < 2
    )
    error_message = "You may not specify more than one `userdata_override_base64`."
  }
}

variable "metadata_http_endpoint_enabled" {
  type        = bool
  default     = true
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 2
  validation {
    condition = (
      var.metadata_http_put_response_hop_limit >= 1
    )
    error_message = "IMDS hop limit must be at least 1 to work."
  }
}

variable "metadata_http_tokens_required" {
  type        = bool
  default     = true
}

variable "placement" {
  type        = list(any)
  default     = []
}

variable "enclave_enabled" {
  type        = bool
  default     = false
}

variable "node_group_terraform_timeouts" {
  type = list(object({
    create = string
    update = string
    delete = string
  }))
  default     = []
}

variable "detailed_monitoring_enabled" {
  type        = bool
  default     = false
}
