# Ensure an offline Gitlab server for Terraform & Packer code
source "googlecompute" "gitlab-offline" {
  project_id              = "simplifymycloud-dev"
  service_account_email   = "288261943767-compute@developer.gserviceaccount.com"
  source_image_family     = "rocky-linux-8"
  ssh_username            = "packer"
  use_os_login            = true
  machine_type            = "n2-highmem-4"
  zone                    = "us-west1-c"
  subnetwork              = "smc-dev-subnet-01"
  image_name              = "gitlab-offline-v03"
  image_description       = "Gitlab server v.0.3"
  image_storage_locations = ["us-west1"]
}

build {
  sources = ["sources.googlecompute.gitlab-offline"]
  provisioner "file" {
    source = "gitlab_gitlab-ee.repo"
    destination = "/tmp/gitlab_gitlab-ee.repo"
  }
  provisioner "file" {
    source = "openssl.cnf"
    destination = "/tmp/openssl.cnf"
  }
  provisioner "shell" {
    environment_vars = [
      "EXTERNAL_URL=http://git.smc.internal",
    ]
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
      "sudo cp /tmp/gitlab_gitlab-ee.repo /etc/yum.repos.d/gitlab_gitlab-ee.repo",
      "sudo dnf install gitlab-ee -y",
      "sudo mkdir -p /etc/gitlab/ssl",
      "sudo chmod 755 /etc/gitlab/ssl",
      "sudo cp /tmp/openssl.cnf /etc/gitlab/ssl/openssl.cnf",
      "sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/gitlab/ssl/git.smc.internal.key -out /etc/gitlab/ssl/git.smc.internal.crt -config /etc/gitlab/ssl/openssl.cnf",
      "sudo gitlab-ctl reconfigure",
    ]
  }
}