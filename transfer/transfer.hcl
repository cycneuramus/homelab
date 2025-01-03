locals {
  strg = "/mnt/jfs/transfer"
}

job "transfer" {
  group "transfer" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "transfer" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "transfer"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "dutchcoders/transfer.sh:v1.6.1"
        ports = ["http"]

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
