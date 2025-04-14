locals {
  strg = "/mnt/jfs/ai"

  image = {
    ui  = "ghcr.io/open-webui/open-webui:v0.6.5"
    api = "docker.io/hlohaus789/g4f:0.5.0.4-slim"
  }
}

job "ai" {
  group "ai" {
    network {
      port "ui" {
        to           = 8080
        host_network = "private"
      }

      port "api" {
        to           = 1337
        host_network = "private"
      }
    }

    task "api" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "gpt"
        port         = "api"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      config {
        image = "${local.image.api}"
        ports = ["api"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        entrypoint = [
          "python", "-m", "g4f.cli", "api", "--gui", "--debug"
        ]
      }
    }

    task "ai" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name         = "ai"
        port         = "ui"
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
        image = "${local.image.ui}"
        ports = ["ui"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/backend/data"
        ]
      }
    }
  }
}
