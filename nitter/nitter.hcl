locals {
  strg = pathexpand("~/cld/nitter")
}

job "nitter" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "eso"
  }

  group "nitter" {
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

      service {
        name     = "nitter"
        port     = "app"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      template {
        data        = file("nitter.conf.tpl")
        destination = "nitter.conf"
      }

      config {
        image = "zedeus/nitter:latest"
        ports = ["app"]

        mount {
          type   = "bind"
          source = "nitter.conf"
          target = "/src/nitter.conf"
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
