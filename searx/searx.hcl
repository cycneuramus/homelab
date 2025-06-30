locals {
  image = {
    searx  = "docker.io/searxng/searxng@sha256:fc36c9c191d58173c2da1ab244cce65640f548962feb16a815e707fc9ec7d8bb"
    valkey = "docker.io/valkey/valkey:8.1-alpine"
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
