# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Security state
# ---------------------------------------------------------------------------------------------------------------------

# Firewall rules
# Hard coding the default rules 
# Disable via the variable
resource "google_compute_firewall" "vpc_network_firewall_icmp" {
  name     = "vpc-network-firewall-icmp-atlantis"
  network  = "${module.vpc.network_name}"
  disabled = "${var.vpc_network_firewall_icmp_disabled}"

  allow {
    protocol = "icmp"
  }

  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["all-instances"]

  depends_on  = [

  ]
}

resource "google_compute_firewall" "vpc_network_firewall_internal" {
  name     = "vpc-network-firewall-internal-atlantis"
  network  = "${module.vpc.network_name}"
  disabled = "${var.vpc_network_firewall_internal_disabled}"

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

  priority      = 65534
  source_tags = ["internal-traffic"]
  target_tags   = ["all-instances"]
}

resource "google_compute_firewall" "vpc_network_firewall_ssh" {
  name     = "vpc-network-firewall-ssh-atlantis"
  network  = "${module.vpc.network_name}"
  disabled = "${var.vpc_network_firewall_ssh_disabled}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-open-external-web"]
}

# adding comments to trigger test atlantis run