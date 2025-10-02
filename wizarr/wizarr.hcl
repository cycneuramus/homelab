locals {
  strg  = "/mnt/jfs/wizarr"
  image = "ghcr.io/wizarrrr/wizarr:v2025.9.7"
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
      # user   = "1000:1000"

      resources {
        memory_max = 1024
      }

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

      template {
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        entrypoint = "/local/entrypoint.sh"

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
