locals {
  strg  = "/mnt/jfs/mollysocket"
  image = "ghcr.io/mollyim/mollysocket:1.7.0-alpine"
}

job "mollysocket" {
  group "mollysocket" {
    network {
      port "http" {
        to           = 8020
        host_network = "private"
      }
    }

    task "mollysocket" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "mollysocket"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:proxying"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        command     = "server"
        working_dir = "/data"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/data"
        ]
      }
    }
  }
}
