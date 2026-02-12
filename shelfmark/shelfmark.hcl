locals {
  strg   = "/mnt/jfs/shelfmark"
  ingest = "/mnt/jfs/cwa/ingest"

  image = {
    shelfmark    = "ghcr.io/calibrain/shelfmark-lite:v1.0.4"
    flaresolverr = "ghcr.io/flaresolverr/flaresolverr:v3.4.6"
  }
}

job "shelfmark" {
  group "shelfmark" {
    network {
      port "shelfmark" {
        to           = 8084
        host_network = "private"
      }

      port "flaresolverr" {
        to           = 8191
        host_network = "private"
      }
    }

    task "shelfmark" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      service {
        name         = "shelfmark"
        port         = "shelfmark"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:curation"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.shelfmark}"
        ports = ["shelfmark"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/config",
          "${local.ingest}:/books",
        ]
      }
    }

    task "flaresolverr" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      service {
        name         = "flaresolverr"
        port         = "flaresolverr"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:proxying"]
      }

      config {
        image = "${local.image.flaresolverr}"
        ports = ["flaresolverr"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
