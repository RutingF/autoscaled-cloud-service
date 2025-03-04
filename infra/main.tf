terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}


// Create the VPC

resource "google_compute_network" "vpc_network" {
  name = "autoscaled-service-network"
  auto_create_subnetworks = "false"
}


// Create the subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "autoscaled-service-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}


// Create Firewall rule - allow traffic for Frontend (HTTP)
resource "google_compute_firewall" "allow-frontend-http" {
  name    = "allow-frontend-http"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["80", "5001"] # HTTP (Frontend) and Flask port
  }

  source_ranges = ["0.0.0.0/0"]
}

// Create Firewall rule - allow traffic for Backend (gRPC over TCP 5000)
resource "google_compute_firewall" "allow-backend-grpc" {
  name    = "allow-backend-grpc"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Define regional health check for backend
resource "google_compute_region_health_check" "backend_health_check" {
  name               = "backend-health-check"
  region            = "us-central1"
  check_interval_sec = 10
  timeout_sec        = 5
  tcp_health_check {
    port = 5000
  }
}

// health check for frontend 
resource "google_compute_health_check" "frontend_health_check" {
  name               = "frontend-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  http_health_check {
    port = 80
  }
}

// Create backend instance 
resource "google_compute_instance" "backend_instance" {
  name         = "backend-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    startup-script = <<-EOT
      sudo apt update -y
      sudo apt -y install python3-pip
      pip3 install flask
      pip3 install grpcio
      pip3 install grpcio-tools
      python3 /app/backend.py &
    EOT
  }
}


// Create frontend instance
resource "google_compute_instance" "frontend_instance" {
  name         = "frontend-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    startup-script = <<-EOT
      sudo apt update -y
      sudo apt -y install python3-pip
      pip3 install flask
      python3 /app/frontend.py &
    EOT
  }
}

// Create Network Load Balancer
resource "google_compute_forwarding_rule" "grpc_nlb" {
  name       = "grpc-nlb"
  region     = "us-central1"
  ip_protocol = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range = "5000"
  backend_service = google_compute_region_backend_service.backend_service.id
}


// Define regional backend service 
resource "google_compute_region_backend_service" "backend_service" {
  name = "backend-service"
  region = "us-central1"
  protocol = "TCP"
  health_checks = [google_compute_region_health_check.backend_health_check.id]
  load_balancing_scheme = "EXTERNAL"
  backend {
    group = google_compute_instance_group.backend_group.id
  }
}


// Create Instance Group for Backend
resource "google_compute_instance_group" "backend_group" {
  name = "backend-group"
  zone = "us-central1-b"
  instances = [google_compute_instance.backend_instance.id]
  named_port {
    name = "grpc"
    port = 5000
  }
}

// Create Application Load Balancer for Frontend 
resource "google_compute_global_address" "frontend_ip" {
  name = "frontend-lb-ip"
}

resource "google_compute_target_http_proxy" "frontend_proxy" {
  name = "frontend-proxy"
  url_map = google_compute_url_map.frontend_map.id
}

resource "google_compute_url_map" "frontend_map" {
  name = "frontend-map"
  default_service = google_compute_backend_service.frontend_service.id
}

resource "google_compute_backend_service" "frontend_service" {
  name = "frontend-service"
  protocol = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  health_checks = [google_compute_health_check.frontend_health_check.id]
  backend {
    group = google_compute_instance_group.frontend_group.id
  }
}

resource "google_compute_instance_group" "frontend_group" {
  name = "frontend-group"
  instances = [google_compute_instance.frontend_instance.id]
  zone = "us-central1-b"
}

resource "google_compute_global_forwarding_rule" "http_rule" {
  name = "frontend-http-rule"
  target = google_compute_target_http_proxy.frontend_proxy.id
  port_range = "80"
}