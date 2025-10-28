locals {
  strg = "/mnt/jfs/nightlio"
  image = {
    api      = "ghcr.io/shirsakm/nightlio-api:0.1.6"
    frontend = "ghcr.io/shirsakm/nightlio-frontend:0.1.6"
  }
}

job "nightlio" {
  group "nightlio" {
    network {
      port "api" {
        to           = 5000
        host_network = "private"
      }

      port "frontend" {
        to           = 80
        host_network = "private"
      }
    }

    task "api" {
      driver = "podman"
      # user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.api}"
        ports = ["api"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data"
        ]
      }
    }

    task "frontend" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "mood"
        port         = "frontend"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        API_URL = "http://${NOMAD_ADDR_api}"
      }

      config {
        image = "${local.image.frontend}"
        ports = ["frontend"]

        # sysctl = {
        #   "net.ipv4.ip_unprivileged_port_start" = "80"
        # }

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
