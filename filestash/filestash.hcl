locals {
  strg  = "/mnt/jfs/filestash"
  nas   = "/mnt/nas/apps"
  image = "docker.io/machines/filestash@sha256:c779ce51011e9db6d007198044e7219ebcf9fcc272ffc958c608e0fab47fa969"
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
          "${local.nas}/filestash:/app/data/files"
        ]
      }
    }
  }
}
