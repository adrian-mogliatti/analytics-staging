variable "prefix" { type = string default = "analytics" }
variable "location" { type = string default = "eastus" }

variable "resource_group_name" {
  type    = string
  default = "${var.prefix}-rg"
}

variable "acr_name" {
  description = "ACR name (lowercase, globally unique prefix). Example: analyticsacr123"
  type = string
}

variable "app_service_plan_name" { type = string default = "${var.prefix}-plan" }

variable "proxy_app_name" { type = string default = "${var.prefix}-proxy" }
variable "backend_app_name" { type = string default = "${var.prefix}-backend" }

variable "basic_auth_user" { type = string default = "staging_user" }
variable "basic_auth_pass" { type = string description = "set via terraform.tfvars or CI" type = string }

variable "admin_email" { type = string description = "alert email address" }

