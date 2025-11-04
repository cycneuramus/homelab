locals {
  strg = "/mnt/jfs/cwa"
  image = {
    cwa          = "ghcr.io/crocodilestick/calibre-web-automated:V3.1.4"
    dl           = "ghcr.io/calibrain/calibre-web-automated-book-downloader-extbp:v0.2.3"
    flaresolverr = "ghcr.io/flaresolverr/flaresolverr:v3.4.3"
  }
}

job "cwa" {
  group "cwa" {
    network {
      port "cwa" {
        to           = 8083
        host_network = "private"
      }

      port "dl" {
        to           = 8084
        host_network = "private"
      }

      port "flaresolverr" {
        to           = 8191
        host_network = "private"
      }
    }

    task "cwa" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 2048
      }

      service {
        name         = "cwa"
        port         = "cwa"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("cwa.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.cwa}"
        ports = ["cwa"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config",
          "${local.strg}/ingest:/cwa-book-ingest",
          "${local.strg}/calibre:/calibre-library",
        ]
      }
    }

    task "dl" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "cwa-dl"
        port         = "dl"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("dl.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.dl}"
        ports = ["dl"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/ingest:/cwa-book-ingest",
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
        tags         = ["local"]
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
