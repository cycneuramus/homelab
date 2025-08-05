locals {
  strg  = "/mnt/jfs/navidrome"
  music = "/mnt/nas/apps/music"
  image = "ghcr.io/navidrome/navidrome:0.58.0"
}

job "navidrome" {
  group "navidrome" {
    network {
      port "http" {
        to           = 4533
        host_network = "private"
      }
    }

    task "navidrome" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "navidrome"
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

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.music}:/music",
          "${local.strg}/db:/data"
        ]

        tmpfs = ["/data/cache"]
      }
    }
  }
}
