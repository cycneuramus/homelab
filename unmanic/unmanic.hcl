locals {
  strg  = "/mnt/jfs/unmanic"
  media = "/mnt/nas/media"
  image = "docker.io/josh5/unmanic:0.2.9"
}

job "unmanic" {
  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "horreum"
    weight    = -50
  }

  group "unmanic" {
    network {
      port "http" {
        to           = 8888
        host_network = "private"
      }
    }

    task "unmanic" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 8192
      }

      service {
        name         = "unmanic"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config",
          "${local.media}:/library"
        ]

        tmpfs = ["/tmp/unmanic"]
      }
    }
  }
}
