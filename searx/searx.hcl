locals {
  strg = pathexpand("~/cld/searx")
}

job "searx" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "eso"
  }

  group "searx" {
    count = 1

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

    task "app" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "searx"
        port     = "app"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        source      = "${local.strg}/.env"
        destination = "env"
        env         = true
      }

      template {
        source      = "${local.strg}/settings.yml.tpl"
        destination = "settings.yml"
      }

      config {
        image = "searxng/searxng:latest"
        ports = ["app"]

        mount {
          type   = "bind"
          source = "settings.yml"
          target = "/etc/searxng/settings.yml"
        }
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]

        command = "redis-server"
        args    = ["--save", "", "--appendonly", "no"]
      }
    }
  }
}
