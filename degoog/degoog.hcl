locals {
  strg = "/mnt/jfs/degoog"
  sock = "..${NOMAD_ALLOC_DIR}/data"

  image = {
    degoog = "ghcr.io/fccview/degoog:0.19.1"
    valkey = "docker.io/valkey/valkey:9.1-alpine"
  }
}

job "degoog" {
  group "degoog" {
    network {
      port "http" {
        to           = 4444
        host_network = "private"
      }
    }

    task "degoog" {
      driver = "podman"

      service {
        name         = "search"
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
        image = "${local.image.degoog}"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data",
          "${local.sock}:/tmp/sock",
        ]
      }
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = <<-EOF
          port 0
          bind 127.0.0.1
          unixsocket /tmp/sock/redis.sock
          unixsocketperm 777
          save ""
        EOF
        destination = "/local/redis.conf"
      }

      config {
        image = "${local.image.valkey}"
        args = [
          "/local/redis.conf"
        ]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock"
        ]
      }
    }
  }
}
