locals {
  strg = "/mnt/jfs/wordpress"
  db   = pathexpand("~/.local/share/wpdb")
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
        image = "mariadb:11.3.2-jammy"
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
        image = "wordpress:6.7.1-php8.3-apache"
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
