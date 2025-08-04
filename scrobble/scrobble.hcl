locals {
  strg = "/mnt/jfs/scrobble"
  image = {
    multi-scrobbler = "ghcr.io/foxxmd/multi-scrobbler:0.9.10"
    koito           = "docker.io/gabehf/koito:v0.0.13"
  }
}

job "scrobble" {
  group "scrobble" {
    network {
      port "multi-scrobbler" {
        to           = 9078
        host_network = "private"
      }

      port "koito" {
        to           = 4110
        host_network = "private"
      }
    }

    task "multi-scrobbler" {
      driver = "podman"
      user   = "0:0"

      service {
        name         = "multi-scrobbler"
        port         = "multi-scrobbler"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("multi-scrobbler.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.multi-scrobbler}"
        ports = ["multi-scrobbler"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/multi-scrobbler:/config"
        ]
      }
    }

    task "koito" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "koito"
        port         = "koito"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("koito.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.koito}"
        ports = ["koito"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/koito:/etc/koito"
        ]
      }
    }
  }
}
