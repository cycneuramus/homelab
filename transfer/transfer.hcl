locals {
  strg  = "/mnt/jfs/transfer"
  image = "docker.io/dutchcoders/transfer.sh:v1.6.1"
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
        tags         = ["private", "monitor:collaboration"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
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
