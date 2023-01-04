# Ensure an offline Gitlab server for Terraform & Packer code
source "googlecompute" "gitlab-offline" {
  project_id              = "simplifymycloud-dev"
  service_account_email   = "288261943767-compute@developer.gserviceaccount.com"
  source_image_family     = "rocky-linux-8"
  ssh_username            = "packer"
  use_os_login            = true
  zone                    = "us-west1-c"
  subnetwork              = "smc-dev-subnet-01"
  image_name              = "gitlab-offline-v1"
  image_description       = "Gitlab server v.1.0"
  image_storage_locations = ["uswest1"]
}

build {
  sources = ["sources.googlecompute.gitlab-offline"]
  provisioner "file" {
    source = "gitlab_gitlab-ee.repo"
    destination = "/etc/yum.repos.d/gitlab_gitlab-ee.repo"
  }
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install unzip -y",
      "sudo dnf install wget -y",
      "sudo dnf install git -y",
      "sudo dnf install curl -y",
      "sudo dnf install openssh-server -y",
      "sudo dnf install perl -y",
      "sudo dnf install postfix -y",
      "sudo systemctl enable postfix",
      "sudo systemctl start postfix",
      "sudo dnf install gitlab-ee -y",
    ]
  }
}