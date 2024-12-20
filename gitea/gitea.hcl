locals {
  strg = "/mnt/jfs/gitea"

  versions = {
    forgejo = "9-rootless"
    valkey  = "8.0-alpine"
  }
}

job "gitea" {
  group "gitea" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "gitea" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "git"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("app.ini.tpl")
        destination = "/local/app.ini"
        uid         = 1000
        gid         = 1000
      }

      config {
        image  = "codeberg.org/forgejo/forgejo:${local.versions.forgejo}"
        ports  = ["http"]
        userns = "keep-id"

        entrypoint = ["/usr/local/bin/forgejo", "-c", "/local/app.ini", "web"]

        logging {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/var/lib/gitea"
        ]

        tmpfs = ["${local.strg}/data/queues/common"]
      }
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image  = "valkey/valkey:${local.versions.valkey}"
        ports  = ["redis"]
        userns = "keep-id"

        command = "valkey-server"
        args = [
          "--save", "300", "1", "--loglevel", "warning"
        ]

        logging {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/redis:/data"
        ]
      }
    }
  }
}
