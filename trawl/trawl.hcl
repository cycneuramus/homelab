locals {
  image = {
    trawl  = "ghcr.io/germondai/trawl:1.2.0"
    valkey = "docker.io/valkey/valkey:9.1-alpine"
  }
}

job "trawl" {
  group "trawl" {
    network {
      port "http" {
        to           = 8191
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "trawl" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      service {
        name         = "bypass"
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
        image = "${local.image.trawl}"
        ports = ["http"]

        # userns = "keep-id"
      }
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image.valkey}"
        ports = ["redis"]

        userns = "keep-id"
      }
    }
  }
}
