locals {
  strg = "/mnt/jfs/karakeep"
  image = {
    karakeep    = "ghcr.io/karakeep-app/karakeep:0.23.2"
    meilisearch = "docker.io/getmeili/meilisearch:v1.13.3"
    chrome      = "gcr.io/zenika-hub/alpine-chrome:123"
  }
}

job "karakeep" {
  group "karakeep" {
    network {
      port "karakeep" {
        to           = 3000
        host_network = "private"
      }
      port "meilisearch" {
        to           = 7700
        host_network = "private"
      }
      port "chrome" {
        to           = 9222
        host_network = "private"
      }
    }

    task "karakeep" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "pin"
        port         = "karakeep"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.karakeep}"
        ports = ["karakeep"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/karakeep:/data"
        ]
      }
    }

    task "meilisearch" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.meilisearch}"
        ports = ["meilisearch"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/meilisearch:/meili_data"
        ]
      }
    }

    task "chrome" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      config {
        image = "${local.image.chrome}"
        ports = ["chrome"]

        args = [
          "--no-sandbox",
          "--disable-gpu",
          "--disable-dev-shm-usage",
          "--remote-debugging-address=0.0.0.0",
          "--remote-debugging-port=9222",
          "--hide-scrollbars"
        ]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
