
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {
  credentials = file("../yourcredentials.json") # Your Service Account JSON file

  project = "yourProjectId"  # Your Project ID
  region  = "us-central1"
  zone    = "us-central1-b"
}
