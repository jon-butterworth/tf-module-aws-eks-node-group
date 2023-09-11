module "this" {
  source  = "git::https://github.com/socratesdao/tf-module-null-label"

  enabled             = var.enabled
  company             = var.company
  tenant              = var.tenant
  region              = var.region
  stage               = var.stage
  name                = var.name
  delimiter           = var.delimiter
  attributes          = var.attributes
  tags                = var.tags
  additional_tag_map  = var.additional_tag_map
  label_order         = var.label_order
  regex_replace_chars = var.regex_replace_chars
  id_length_limit     = var.id_length_limit
  label_key_case      = var.label_key_case
  label_value_case    = var.label_value_case
  descriptor_formats  = var.descriptor_formats
  labels_as_tags      = var.labels_as_tags

  context = var.context
}

variable "context" {
  type = any
  default = {
    enabled             = true
    company             = "socrates"
    tenant              = null
    region              = "eu-west-2"
    stage               = null
    name                = null
    delimiter           = null
    attributes          = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = null
    label_order         = []
    id_length_limit     = null
    label_key_case      = null
    label_value_case    = null
    descriptor_formats  = {}
    labels_as_tags = ["unset"]
  }

  validation {
    condition     = lookup(var.context, "label_key_case", null) == null ? true : contains(["lower", "title", "upper"], var.context["label_key_case"])
    error_message = "Allowed values: `lower`, `title`, `upper`."
  }

  validation {
    condition     = lookup(var.context, "label_value_case", null) == null ? true : contains(["lower", "title", "upper", "none"], var.context["label_value_case"])
    error_message = "Allowed values: `lower`, `title`, `upper`, `none`."
  }
}

variable "enabled" {
  type        = bool
  default     = null
}

variable "company" {
  type        = string
  default     = null
}

variable "tenant" {
  type        = string
  default     = null
}

variable "region" {
  type        = string
  default     = null
}

variable "stage" {
  type        = string
  default     = null
}

variable "name" {
  type        = string
  default     = null
}

variable "delimiter" {
  type        = string
  default     = null
}

variable "attributes" {
  type        = list(string)
  default     = []
}

variable "labels_as_tags" {
  type        = set(string)
  default     = ["default"]
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "additional_tag_map" {
  type        = map(string)
  default     = {}
}

variable "label_order" {
  type        = list(string)
  default     = null
}

variable "regex_replace_chars" {
  type        = string
  default     = null
}

variable "id_length_limit" {
  type        = number
  default     = null

  validation {
    condition     = var.id_length_limit == null ? true : var.id_length_limit >= 6 || var.id_length_limit == 0
    error_message = "The id_length_limit must be >= 6 if supplied (not null), or 0 for unlimited length."
  }
}

variable "label_key_case" {
  type        = string
  default     = null

  validation {
    condition     = var.label_key_case == null ? true : contains(["lower", "title", "upper"], var.label_key_case)
    error_message = "Allowed values: `lower`, `title`, `upper`."
  }
}

variable "label_value_case" {
  type        = string
  default     = null

  validation {
    condition     = var.label_value_case == null ? true : contains(["lower", "title", "upper", "none"], var.label_value_case)
    error_message = "Allowed values: `lower`, `title`, `upper`, `none`."
  }
}

variable "descriptor_formats" {
  type        = any
  default     = {}
}