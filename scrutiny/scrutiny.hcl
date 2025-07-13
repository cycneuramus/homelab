locals {
  strg = pathexpand("/mnt/jfs/scrutiny")

  image = {
    web       = "ghcr.io/analogj/scrutiny:v0.8.1-web"
    collector = "ghcr.io/analogj/scrutiny:v0.8.1-collector"
    influxdb  = "docker.io/influxdb:2.2.0-alpine"
  }
}

job "scrutiny" {
  group "web" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }

      port "influxdb" {
        to           = 8086
        host_network = "private"
      }
    }

    task "influxdb" {
      driver = "podman"
      user   = "1000:1000"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      service {
        name         = "influxdb"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      config {
        image = "${local.image.influxdb}"
        ports = ["influxdb"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/influxdb:/var/lib/influxdb2",
        ]
      }
    }

    task "web" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "scrutiny"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("web.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.web}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/opt/scrutiny/config",
        ]
      }
    }
  }

  group "collector" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    task "collector" {
      driver = "podman"

      template {
        data        = file("collector.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.collector}"

        socket     = "root"
        privileged = true

        logging = {
          driver = "journald"
        }

        volumes = [
          "/dev:/dev:ro",
          "/run/udev:/run/udev:ro",
          "${local.strg}/config:/opt/scrutiny/config",
        ]
      }
    }
  }
}
