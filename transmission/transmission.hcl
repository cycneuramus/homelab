locals {
  dl    = pathexpand("~/dl/torrent")
  strg  = "/mnt/jfs/transmission"
  image = "ghcr.io/linuxserver/transmission:4.1.1"
}

job "transmission" {
  group "transmission" {
    network {
      port "http" {
        to           = 9091
        host_network = "private"
      }
    }

    task "transmission" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "torrent"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        TZ = "Europe/Stockholm"
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
          "${local.dl}:/downloads"
        ]
      }
    }
  }
}
