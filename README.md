# HDFS Cloud Starter

Deploy a production-ready Hadoop HDFS cluster on Google Cloud Platform using Terraform and Ansible.

---

## Features

- Automated GCP infrastructure (VPC, firewall, VMs)
- One-command Hadoop/HDFS installation and configuration
- Secure SSH access (restricted to your IP)
- Easy scaling and cleanup

---

## Prerequisites

- [Terraform](https://terraform.io/downloads) (>= 1.0)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) (>= 2.9)
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- `jq` (for JSON parsing)

---

## Quick Start

### 1. Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Configure Deployment

Edit `providers/gcp/terraform/terraform.tfvars`:

```hcl
gcp_project_id = "your-gcp-project-id"
gcp_region     = "us-central1"
gcp_zone       = "us-central1-a"
instance_type  = "e2-medium"
image          = "ubuntu-os-cloud/ubuntu-2204-lts"
worker_count   = 2
allow_ssh_cidr = "YOUR_IP/32"  # get your IP: curl -4 ifconfig.me
ssh_public_key_file = "~/.ssh/id_rsa.pub"
```

### 3. Deploy the Cluster

```bash
chmod +x hdfs-deploy.sh
./hdfs-deploy.sh deploy
```

### 4. Access the Cluster

- **NameNode Web UI**: `http://MASTER_IP:9870`
- **Secondary NameNode UI**: `http://MASTER_IP:9868`
- **SSH to Master**: `ssh ubuntu@MASTER_IP`

### 5. Test HDFS

```bash
ssh ubuntu@MASTER_IP
sudo su - hadoop
hdfs dfs -ls /
hdfs dfs -mkdir /test
hdfs dfs -put /etc/hosts /test/
hdfs dfsadmin -report
```

### 6. Destroy Resources

```bash
./hdfs-deploy.sh destroy
```

---

## Project Structure

```
hdfs-cloud-starter/
├── hdfs-deploy.sh
├── generate-inventory.sh
├── providers/gcp/terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── ansible/
    ├── hdfs-cluster.yml
    ├── inventory.yml
    └── templates/
        ├── core-site.xml.j2
        ├── hdfs-site.xml.j2
        └── workers.j2
```

---

## Scaling & Customization

- **More workers**: Change `worker_count` in `terraform.tfvars`
- **Instance type**: Change `instance_type`
- **Hadoop version/config**: Edit `ansible/hdfs-cluster.yml` and templates

---

## Troubleshooting

- **SSH issues**: Check your IP and update `allow_ssh_cidr`
- **Instance status**: `gcloud compute instances list`
- **Service status**: SSH to master, run `jps` and check logs

---

## License

MIT License
