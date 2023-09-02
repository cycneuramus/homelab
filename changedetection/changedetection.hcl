locals {
  strg = pathexpand("~/cld/changedetection")
}

job "changedetection" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "changedetection" {
    count = 1

    network {
      port "http" {
        to           = 2426
        host_network = "private"
      }

      port "browser" {
        to           = 4444
        host_network = "private"
      }
    }

    task "changedetection" {
      driver = "docker"

      service {
        name     = "change"
        port     = "http"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      env {
        PORT          = "2426"
        PUID          = "1000"
        PGID          = "1000"
        WEBDRIVER_URL = "${NOMAD_ADDR_browser}/wd/hub"
        HIDE_REFERRER = "true"
      }

      config {
        image = "ghcr.io/dgtlmoon/changedetection.io"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/datastore"
        }
      }
    }

    task "browser" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      env {
        SCREEN_WIDTH    = "1920"
        SCREEN_HEIGHT   = "1080"
        SCREEN_DEPTH    = "24"
        VNC_NO_PASSWORD = "1"
      }

      config {
        image = "selenium/standalone-chrome-debug:3.141.59"
        ports = ["browser"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/datastore"
        }
      }
    }
  }
}
