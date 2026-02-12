locals {
  strg  = "/mnt/jfs/dbh"
  image = "ghcr.io/astral-sh/uv:0.10-python3.13-alpine"
}

job "dbh" {
  group "dbh" {
    network {
      port "http" {
        to           = 8000
        host_network = "private"
      }
    }

    task "dbh" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "dbh"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:personal"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        working_dir = "/app"
        entrypoint  = "/local/entrypoint.sh"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/app:/app",
          "${local.strg}/data:/data:ro"
        ]
      }
    }
  }
}
