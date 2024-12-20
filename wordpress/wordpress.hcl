locals {
  strg = "/mnt/jfs/wordpress"
  db   = pathexpand("~/.local/share/wpdb")

  version = {
    mariadb   = "11.2.5-jammy"
    wordpress = "6.6.2-php8.3-apache"
  }
}

job "wordpress" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
  }

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
        data        = file("env_db")
        destination = "env_db"
        env         = true
      }

      config {
        image = "mariadb:${local.version.mariadb}"
        ports = ["db"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.db}:/var/lib/mysql"
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
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "wordpress:${local.version.wordpress}"
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
