locals {
  strg = "/mnt/jfs/wordpress"

  image = {
    mariadb   = "docker.io/mariadb:11.8.2-ubi9"
    wordpress = "docker.io/wordpress:6.8.1-php8.3-apache"
  }
}

job "wordpress" {
  group "wordpress" {
    network {
      port "db" {
        to           = 3306
        host_network = "private"
      }

      port "http" {
        to           = 80
        host_network = "private"
      }
    }

    task "db" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      template {
        data        = file(".env-db")
        destination = ".env-db"
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

    task "wordpress" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "hannes"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      service {
        name         = "hannes-db"
        port         = "db"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file(".env-app")
        destination = ".env-app"
        env         = true
      }

      config {
        image = "${local.image.wordpress}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "80"
        }

        volumes = [
          "${local.strg}/data:/var/www/html"
        ]
      }
    }
  }
}
