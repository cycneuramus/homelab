locals {
  strg = "/mnt/jfs/booklore"
  image = {
    booklore = "ghcr.io/grimmory-tools/grimmory:v3.0.0"
    mariadb  = "ghcr.io/mariadb/mariadb:11.8.3-ubi9"
  }
}

job "booklore" {
  group "booklore" {
    network {
      port "db" {
        to           = 3306
        host_network = "private"
      }

      port "http" {
        to           = 6060
        host_network = "private"
      }
    }

    task "db" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "books-db"
        port         = "db"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      resources {
        memory_max = 2048
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      template {
        data        = file("db.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.mariadb}"
        ports = ["db"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/db:/var/lib/mysql"
        ]
      }
    }

    task "booklore" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 4096
      }

      service {
        name         = "books"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("app.env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.booklore}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/app/data",
          "${local.strg}/books:/books",
          "${local.strg}/ingest:/bookdrop"
        ]
      }
    }
  }
}
