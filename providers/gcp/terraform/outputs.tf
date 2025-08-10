output "master_ip" {
  value       = google_compute_instance.master.network_interface[0].access_config[0].nat_ip
  description = "Public IP of the master node"
}

output "master_private_ip" {
  value       = google_compute_instance.master.network_interface[0].network_ip
  description = "Private IP of the master node"
}

output "worker_ips" {
  value       = [for w in google_compute_instance.workers : w.network_interface[0].access_config[0].nat_ip]
  description = "Public IPs of worker nodes"
}

output "worker_private_ips" {
  value       = [for w in google_compute_instance.workers : w.network_interface[0].network_ip]
  description = "Private IPs of worker nodes"
}

output "cluster_info" {
  value = {
    namenode_web_ui   = "http://${google_compute_instance.master.network_interface[0].access_config[0].nat_ip}:9870"
    namenode_admin_ui = "http://${google_compute_instance.master.network_interface[0].access_config[0].nat_ip}:9868"
    master_ssh        = "ssh ubuntu@${google_compute_instance.master.network_interface[0].access_config[0].nat_ip}"
  }
  description = "Cluster access information"
}
