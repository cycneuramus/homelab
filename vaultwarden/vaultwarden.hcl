locals {
  strg  = "/mnt/jfs/vaultwarden"
  image = "ghcr.io/dani-garcia/vaultwarden:1.35.2-alpine"
}

job "vaultwarden" {
  group "vaultwarden" {
    network {
      port "app" {
        to           = 8080
        host_network = "private"
      }
    }

    task "vaultwarden" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "vaultwarden"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public", "monitor:security"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["app"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/data"
        ]
      }
    }
  }
}
