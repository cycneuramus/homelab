locals {
  strg   = "/mnt/jfs/ephemera"
  ingest = "/mnt/jfs/cwa/ingest"
  dl     = pathexpand("~/dl")

  image = {
    ephemera     = "ghcr.io/orwellianepilogue/ephemera:1.3.1"
    flaresolverr = "ghcr.io/flaresolverr/flaresolverr:v3.4.5"
  }
}

job "ephemera" {
  group "ephemera" {
    network {
      port "ephemera" {
        to           = 8286
        host_network = "private"
      }

      port "flaresolverr" {
        to           = 8191
        host_network = "private"
      }
    }

    task "ephemera" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 1024
      }

      service {
        name         = "ephemera"
        port         = "ephemera"
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
        image = "${local.image.ephemera}"
        ports = ["ephemera"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data",
          "${local.ingest}:/app/ingest",
          "${local.dl}:/app/downloads",
        ]
      }
    }

    task "flaresolverr" {
      driver = "podman"
      # user   = "1000:1000"

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
