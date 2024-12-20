locals {
  strg    = "/mnt/jfs/fmd"
  version = "v0.8.0"
}

job "fmd" {
  group "fmd" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "fmd" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "fmd"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("config.yml.tpl")
        destination = "/local/config.yml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "registry.gitlab.com/nulide/findmydeviceserver:${local.version}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        entrypoint = ["/fmd/server", "-c", "/local/config.yml", "serve"]

        volumes = [
          "${local.strg}/db:/fmd/db"
        ]
      }
    }
  }
}