locals {
  image = "ghcr.io/miniflux/miniflux:2.2.9"
}

job "miniflux" {
  group "miniflux" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "miniflux" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "rss"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
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
      }
    }
  }
}
