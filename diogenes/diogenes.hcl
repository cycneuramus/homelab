locals {
  strg     = "/mnt/jfs/diogenes"
  image    = "ghcr.io/cycneuramus/containers"
  datapath = split("=", chomp(file("datapath.env")))[1]
}

job "diogenes" {
  group "diogenes" {
    network {
      port "http" {
        to           = 8888
        host_network = "private"
      }
    }

    task "diogenes" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "diogenes"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:personal"]
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.datapath}:/data",
          "${local.strg}:/home/diogenes/.diogenes"
        ]
      }
    }
  }
}
