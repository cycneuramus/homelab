locals {
  media = "/mnt/nas/media/tv/yt"
  strg  = "/mnt/jfs/pinchflat"
}

job "pinchflat" {
  group "pinchflat" {
    network {
      port "http" {
        to           = 8945
        host_network = "private"
      }
    }

    task "pinchflat" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      service {
        name         = "pinchflat"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        JOURNAL_MODE = "delete"
        TZ           = "Europe/Stockholm"
      }

      config {
        image = "ghcr.io/kieraneglin/pinchflat:v2024.12.31"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/config",
          "${local.media}:/downloads"
        ]
      }
    }
  }
}
