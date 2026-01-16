# 1. Define the Provider
provider "google" {
  project = "your-project-id" # Replace with your GCP Project ID
  region  = "us-central1"
  zone    = "us-central1-a"
}

# 2. Create a Firewall Rule to allow HTTP traffic (Port 80)
resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# 3. Define the N2 Ubuntu Instance
resource "google_compute_instance" "web_server" {
  name         = "ubuntu-docker-webserver"
  machine_type = "n2-standard-2" # N2 machine type
  zone         = "us-central1-a"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts" # Ubuntu 22.04 LTS
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Leaving this empty assigns a public IP
    }
  }

  # 4. Startup Script to install Docker and run the Container
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Update and install Docker
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Run NGINX Webserver Container
    sudo docker run -d -p 80:80 --name webserver nginx
  EOF
}

# Output the Public IP
output "public_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}