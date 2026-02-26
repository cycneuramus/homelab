locals {
  strg  = "/mnt/jfs/unmanic"
  media = "/mnt/nas/media"
  image = "docker.io/josh5/unmanic:0.4.0"
  logs  = "..${NOMAD_ALLOC_DIR}/data"
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
      user   = "1000:1000"

      resources {
        memory_max = 8192
      }

      service {
        name         = "unmanic"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:curation"]
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
          "${local.strg}/data/config:/config/.unmanic/config",
          "${local.strg}/data/plugins:/config/.unmanic/plugins",
          "${local.strg}/data/userdata:/config/.unmanic/userdata",
          "${local.media}:/library"
        ]

        tmpfs = [
          "/config/.unmanic/logs:size=50000k"
        ]
      }
    }
  }
}
