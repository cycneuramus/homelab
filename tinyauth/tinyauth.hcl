locals {
  image = "ghcr.io/steveiliop56/tinyauth:v3.6.1"
}

job "tinyauth" {
  group "tinyauth" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "tinyauth" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "auth"
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
      }
    }
  }
}
