locals {
  strg  = "/mnt/jfs/wizarr"
  image = "ghcr.io/wizarrrr/wizarr:2025.7.8"
}

job "wizarr" {
  group "wizarr" {
    network {
      port "http" {
        to           = 5690
        host_network = "private"
      }
    }

    task "wizarr" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "wizarr"
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
          "${local.strg}/data:/data/database",
          "${local.strg}/cache:/data/.cache"
        ]
      }
    }
  }
}
