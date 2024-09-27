packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.16"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}