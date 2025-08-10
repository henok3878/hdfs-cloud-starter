variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "instance_type" {
  type    = string
  default = "e2-medium"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "image" {
  type    = string
  default = "debian-cloud/debian-11"
}

variable "allow_ssh_cidr" {
  type = string
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
