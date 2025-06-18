locals {
  strg  = "/mnt/jfs/jellyfin"
  media = "/mnt/nas/media"
  music = "/mnt/nas/music"
  image = "ghcr.io/linuxserver/jellyfin:10.10.7"
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
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
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

        socket = "root"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.media}:/mnt/cryptnas/media",
          "${local.music}:/mnt/music",
          "${local.strg}/config:/config",
          "local/encoding.xml:/config/encoding.xml"
        ]

        devices = ["/dev/dri"]
      }
    }
  }
}
