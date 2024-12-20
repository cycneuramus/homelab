locals {
  strg      = "/mnt/jfs/audiobookshelf"
  mnt-crypt = "/mnt/crypt"
  version   = "2.17.5"
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
        image = "ghcr.io/advplyr/audiobookshelf:${local.version}"
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
          "${local.mnt-crypt}/audiobookshelf:/audiobooks/kids"
        ]
      }
    }
  }
}
