locals {
  strg  = "/mnt/jfs/ocis"
  data  = "/mnt/nas/ocis"
  image = "docker.io/owncloud/ocis:7.0.0"
}

job "ocis" {
  group "ocis" {
    network {
      port "http" {
        to           = 9200
        host_network = "private"
      }

      port "nats" {
        to           = 9233
        host_network = "private"
      }

      port "gateway" {
        to           = 9142
        host_network = "private"
      }

      port "wopi" {
        to           = 9300
        host_network = "private"
      }
    }

    task "ocis" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "ocis"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env-ocis")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http", "nats", "gateway"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/etc/ocis",
          "${local.data}:/var/lib/ocis"
        ]
      }
    }

    task "collaboration" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "ocis-wopi"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env-collaboration")
        destination = "env"
        env         = true
      }

      config {
        image      = "${local.image}"
        ports      = ["wopi"]
        entrypoint = ["ocis", "collaboration", "server"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/etc/ocis",
        ]
      }
    }
  }
}
