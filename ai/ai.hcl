locals {
  strg  = "/mnt/jfs/ai"
  image = "ghcr.io/open-webui/open-webui:0.5.18"
}

job "ai" {
  group "ai" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "ai" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name         = "ai"
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

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/backend/data"
        ]
      }
    }
  }
}
