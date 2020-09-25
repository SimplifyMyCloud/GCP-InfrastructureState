module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.2"

    project_id   = "iq9-ops-7523"
    network_name = "iq9-ops-network"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "iq9-ops-network-subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "false"
            subnet_flow_logs      = "true"
            description           = "iq9 ops env network subnet 01"
        },
        {
            subnet_name           = "iq9-ops-network-subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "us-west1"
            subnet_private_access = "false"
            subnet_flow_logs      = "true"
            description           = "iq9 ops env network subnet 02"
        },
        {
            subnet_name               = "iq9-ops-network-subnet-03"
            subnet_ip                 = "10.10.30.0/24"
            subnet_region             = "us-west1"
            subnet_private_access     = "false"
            subnet_flow_logs          = "true"
            description               = "iq9 ops env network subnet 03"
        }
    ]

    secondary_ranges = {
        subnet-01 = []

        subnet-02 = []

        subnet-03 = []
    }

    routes = [
        {
            name                   = "egress-internet"
            description            = "route through IGW to access internet"
            destination_range      = "0.0.0.0/0"
            tags                   = "egress-inet"
            next_hop_internet      = "true"
        },
    ]
}