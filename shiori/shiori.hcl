locals {
  strg  = "/mnt/jfs/shiori"
  image = "ghcr.io/go-shiori/shiori:alpine-v1.7.4"
}

job "shiori" {
  group "shiori" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "shiori" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "shiori"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
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
