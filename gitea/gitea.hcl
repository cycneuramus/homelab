locals {
  strg = pathexpand("~/cld/gitea")
}

job "gitea" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "ocl"
  }

  group "gitea" {
    count = 1

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
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "git"
        port     = "http"
        provider = "nomad"
        tags     = ["public"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      template {
        data        = file("app.ini.tpl")
        destination = "/local/app.ini"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "gitea/gitea:latest-rootless"
        ports = ["http"]

        entrypoint = ["/usr/local/bin/gitea", "-c", "/local/app.ini", "web"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/var/lib/gitea"
        }
      }
    }

    task "redis" {
      driver = "docker"
      user   = "1000:1000"

      config {
        image = "redis:alpine"
        ports = ["redis"]

        command = "redis-server"
        args = [
          "--save", "300", "1", "--loglevel", "warning"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/redis"
          target = "/data"
        }
      }
    }
  }
}
