locals {
  strg  = "/mnt/jfs/filestash"
  crypt = "/mnt/crypt/filestash"
  image = "docker.io/machines/filestash@sha256:7c713737f56782b19eaa12b81310109a404a0566eee23cd20d7c0612dd99135c"
}

job "filestash" {
  group "filestash" {
    network {
      port "http" {
        to           = 8334
        host_network = "private"
      }
    }

    task "filestash" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "filestash"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        force_pull = true

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data/state",
          "${local.crypt}:/app/data/files"
        ]
      }
    }
  }
}
