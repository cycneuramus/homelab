locals {
  strg  = "/mnt/jfs/jellyfin"
  media = "/mnt/nas/media"
  image = "ghcr.io/jellyfin/jellyfin:10.10.7"
}

job "jellyfin" {
  group "jellyfin" {
    network {
      port "http" {
        to           = 8096
        host_network = "private"
      }
    }

    task "jellyfin" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 8192
      }

      service {
        name         = "jellyfin"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      env {
        TZ               = "Europe/Stockholm"
        JELLYFIN_LOG_DIR = "/tmp"
      }

      template {
        data        = file("encoding.xml.tpl")
        destination = "local/encoding.xml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/config",
          "${local.media}:/mnt/cryptnas/media",
          "local/encoding.xml:/config/config/encoding.xml"
        ]

        devices = ["/dev/dri/renderD128"]
      }
    }
  }
}
