locals {
  strg = "/mnt/jfs/changedetection"
  version = {
    changedetection = "0.48.05"
    browser         = "3.141.59"
  }
}

job "changedetection" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "changedetection" {
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
      driver = "podman"

      service {
        name         = "change"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PORT          = "2426"
        WEBDRIVER_URL = "${NOMAD_ADDR_browser}/wd/hub"
        HIDE_REFERRER = "true"
      }

      config {
        image = "ghcr.io/dgtlmoon/changedetection.io:${local.version.changedetection}"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/datastore"
        ]
      }
    }

    task "browser" {
      driver = "podman"

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
        image = "selenium/standalone-chrome-debug:${local.version.browser}"
        ports = ["browser"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
