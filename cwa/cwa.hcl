locals {
  strg  = "/mnt/jfs/cwa"
  image = "ghcr.io/crocodilestick/calibre-web-automated:V3.1.4"
}

job "cwa" {
  group "cwa" {
    network {
      port "cwa" {
        to           = 8083
        host_network = "private"
      }
    }

    task "cwa" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 2048
      }

      service {
        name         = "cwa"
        port         = "cwa"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:entertainment"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["cwa"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config",
          "${local.strg}/ingest:/cwa-book-ingest",
          "${local.strg}/calibre:/calibre-library",
        ]
      }
    }
  }
}
