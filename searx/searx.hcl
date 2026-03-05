locals {
  image = {
    searx  = "docker.io/searxng/searxng@sha256:dc9c7aae0b77f8cd819dd8c7e6d489eab456000838e062c399f2bf37d230500e"
    valkey = "docker.io/valkey/valkey:9.0-alpine"
  }
}

job "searx" {
  group "searx" {
    network {
      port "app" {
        to           = 8080
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "searx" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "searx"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("settings.yml.tpl")
        destination = "settings.yml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image.searx}"
        ports = ["app"]

        force_pull = true

        logging = {
          driver = "journald"
        }

        volumes = [
          "settings.yml:/etc/searxng/settings.yml"
        ]
      }
    }

    task "redis" {
      driver = "podman"

      config {
        image = "${local.image.valkey}"
        ports = ["redis"]

        logging = {
          driver = "journald"
        }

        args = ["--save", "", "--appendonly", "no"]
      }
    }
  }
}
