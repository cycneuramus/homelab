locals {
  strg = "/mnt/jfs/gameyfin"
  nas  = "/mnt/nas/apps/gameyfin"
  logs = "..${NOMAD_ALLOC_DIR}/data"

  image = "ghcr.io/gameyfin/gameyfin:2.4.0"
}

job "gameyfin" {
  group "gameyfin" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "gameyfin" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 1024
      }

      service {
        name         = "games"
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

      template {
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        entrypoint = [
          "/local/entrypoint.sh"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/db:/opt/gameyfin/db",
          "${local.strg}/data:/opt/gameyfin/data",
          "${local.strg}/plugindata:/opt/gameyfin/plugindata",
          "${local.logs}:/opt/gameyfin/logs",
          "${local.nas}:/games",
        ]
      }
    }
  }
}
