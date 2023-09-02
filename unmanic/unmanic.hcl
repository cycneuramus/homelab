locals {
  strg     = pathexpand("~/cld/unmanic")
  node_cfg = pathexpand("~/.local/share/unmanic")
  node_cch = pathexpand("~/.cache/unmanic")
}

job "unmanic" {
  group "server" {
    count = 1

    network {
      port "http" {
        to           = 8888
        host_network = "private"
      }
    }

    task "server" {
      constraint {
        attribute = "${attr.unique.hostname}"
        value     = "apex"
      }

      resources {
        memory_max = 8192
      }

      driver = "docker"

      service {
        name     = "unmanic"
        port     = "http"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      template {
        data        = file("settings-server.json.tpl")
        destination = "settings.json"
      }

      config {
        image = "josh5/unmanic:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "settings.json"
          target = "/config/.unmanic/config/settings.json"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        mount {
          type   = "bind"
          source = "${local.node_cch}"
          target = "/tmp/unmanic"
        }

        mount {
          type   = "bind"
          source = pathexpand("~/mnt/hdd/media")
          target = "/library"
        }

        devices = [
          {
            host_path = "/dev/dri"
          }
        ]
      }
    }
  }
}
