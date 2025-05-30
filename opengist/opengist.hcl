locals {
  strg  = "/mnt/jfs/opengist"
  image = "ghcr.io/thomiceli/opengist:1.10.0"
}

job "opengist" {
  group "opengist" {
    network {
      port "http" {
        to           = 6157
        host_network = "private"
      }
    }

    task "opengist" {
      driver = "podman"

      service {
        name         = "gist"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file("config.yml.tpl")
        destination = "/local/config.yml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        entrypoint = ["./opengist", "--config", "/local/config.yml"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/opengist"
        ]
      }
    }
  }
}
