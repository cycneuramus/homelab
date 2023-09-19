locals {
  strg = pathexpand("~/cld/vaultwarden")
}

job "vaultwarden" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "vaultwarden" {
    count = 1

    network {
      port "app" {
        to           = 8080
        host_network = "private"
      }
    }

    task "app" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "vaultwarden"
        port     = "app"
        provider = "nomad"
        tags     = ["public"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "vaultwarden/server:alpine"
        ports = ["app"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/data"
        }
      }
    }
}
