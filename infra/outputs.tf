// note: must match the resource names in the main.tf file

// output of backend NLB IP
output "backend_nlb_ip" {
  value = google_compute_forwarding_rule.grpc_nlb.ip_address
}