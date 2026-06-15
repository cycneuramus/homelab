locals {
  image = "ghcr.io/remvze/moodist:v2.6.0"
}

job "moodist" {
  group "moodist" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "moodist" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "moodist"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
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
