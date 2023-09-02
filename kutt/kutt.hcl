locals {
  strg = pathexpand("~/cld/kutt")
}

job "kutt" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "kutt" {
    count = 1

    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }

      port "db" {
        to           = 5432
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "app" {
      driver = "docker"

      service {
        name     = "kutt"
        port     = "app"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "kutt/kutt"
        ports = ["app"]

        command = "./wait-for-it.sh"
        args    = ["${NOMAD_ADDR_db}", "--", "npm", "start"]
      }
    }

    task "db" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "kutt-db"
        port     = "db"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file("env_db")
        destination = "env_db"
        env         = true
      }

      config {
        image = "postgres:15-alpine"
        ports = ["db"]

        mount {
          type   = "bind"
          source = "${local.strg}/db"
          target = "/var/lib/postgresql/data"
        }
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]
      }
    }
  }
}
