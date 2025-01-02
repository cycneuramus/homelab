locals {
  strg    = "/mnt/jfs/ocis"
  data    = "/mnt/nas/ocis"
  version = "7.0.0"
}

job "ocis" {
  group "ocis" {
    network {
      port "http" {
        to           = 9200
        host_network = "private"
      }
    }

    task "ocis" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "ocis"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "docker.io/owncloud/ocis:${local.version}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/etc/ocis",
          "${local.data}:/var/lib/ocis"
        ]
      }
    }
  }
}
