locals {
  strg  = "/mnt/jfs/audiobookshelf"
  nas   = "/mnt/nas/apps"
  image = "ghcr.io/advplyr/audiobookshelf:2.25.1"
}

job "audiobookshelf" {
  group "audiobookshelf" {
    network {
      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "audiobookshelf" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name         = "audiobooks"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "80"
        }

        volumes = [
          "${local.strg}/db:/config",
          "${local.strg}/metadata:/metadata",
          "${local.nas}/audiobooks:/audiobooks/kids"
        ]
      }
    }
  }
}
