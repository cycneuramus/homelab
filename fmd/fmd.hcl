locals {
  strg  = "/mnt/jfs/fmd"
  image = "registry.gitlab.com/fmd-foss/fmd-server:v0.11.0"
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
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        entrypoint = ["/opt/fmd-server", "-c", "/local/config.yml", "serve"]

        volumes = [
          "${local.strg}/db:/var/lib/fmd-server/db"
        ]
      }
    }
  }
}
