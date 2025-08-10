terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

resource "google_compute_network" "vpc" {
  name                    = "hadoop-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "hadoop-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "ssh" {
  name    = "hadoop-allow-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [var.allow_ssh_cidr]
}

resource "google_compute_firewall" "internal" {
  name    = "hadoop-allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = [google_compute_subnetwork.subnet.ip_cidr_range]
}

resource "google_compute_firewall" "web_ui" {
  name    = "hadoop-allow-web-ui"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["9870", "9868", "8088", "19888"]
  }
  source_ranges = [var.allow_ssh_cidr]
  target_tags   = ["hadoop-master"]
}

locals {
  startup = <<-EOT
    #!/bin/bash
    set -eux
    
    # wait for cloud-init to complete
    cloud-init status --wait
    
    # install required packages
    apt-get update -y
    apt-get install -y python3 python3-pip rsync curl wget
    
    # ensure SSH is ready
    systemctl enable ssh
    systemctl start ssh
    
    # create a marker file to indicate setup is complete
    touch /tmp/setup-complete
  EOT
}

resource "google_compute_instance" "master" {
  name         = "hadoop-master"
  machine_type = var.instance_type
  zone         = var.gcp_zone
  tags         = ["hadoop", "hadoop-master"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {} # public IP for quickstart
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_file)}"
  }

  metadata_startup_script = local.startup
}

resource "google_compute_instance" "workers" {
  count        = var.worker_count
  name         = "hadoop-worker-${count.index + 1}"
  machine_type = var.instance_type
  zone         = var.gcp_zone
  tags         = ["hadoop", "hadoop-worker"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_file)}"
  }

  metadata_startup_script = local.startup
}
