locals {
  strg = "/mnt/jfs/dispatcharr"

  image = {
    dispatcharr = "ghcr.io/dispatcharr/dispatcharr:0.27.2"
    valkey      = "docker.io/valkey/valkey:9.1-alpine"
  }
}

job "dispatcharr" {
  group "dispatcharr" {
    network {
      port "http" {
        to           = 9191
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "dispatcharr" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 4096
      }

      service {
        name         = "dispatcharr"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("app.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.dispatcharr}"
        ports = ["http"]

        # userns = "keep-id"

        logging {
          driver = "journald"
        }

        devices = ["/dev/dri/renderD128"]

        volumes = [
          "${local.strg}:/data"
        ]
      }
    }

    task "celery" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file("celery.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.dispatcharr}"

        # userns = "keep-id"

        entrypoint = ["/app/docker/entrypoint.celery.sh"]

        logging {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/data"
        ]
      }
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image.valkey}"
        ports = ["redis"]

        userns = "keep-id"

        logging {
          driver = "journald"
        }
      }
    }
  }
}
