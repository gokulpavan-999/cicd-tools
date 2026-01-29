variable "project" {
    default = "roboshop"
}

variable "environment" {
    default = "dev"
}

variable "zone_name" {
  type        = string
  default     = "pavandevops.fun"
  description = "description"
}

variable "zone_id" {
  type        = string
  default     = "Z08654702BW8GGH0J30B"
  description = "description"
}

variable "sonar" {
  default = false
}
