locals {
  media = "/mnt/nas/media/tv/yt"
  strg  = "/mnt/jfs/pinchflat"
  image = "ghcr.io/kieraneglin/pinchflat:v2025.6.6"
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
        memory_max = 2048
      }

      service {
        name         = "pinchflat"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:curation"]
      }

      env {
        # JOURNAL_MODE = "delete"
        LOG_LEVEL = "warning"
        TZ        = "Europe/Stockholm"
      }

      config {
        image = "${local.image}"
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
