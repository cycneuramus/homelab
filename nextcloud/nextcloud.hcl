locals {
  strg  = "/mnt/jfs/nextcloud"
  crypt = "/mnt/crypt"
  sock  = pathexpand("~/cld/nextcloud/sock")

  image = {
    nextcloud = "docker.io/nextcloud:31.0.4-apache"
    collabora = "docker.io/collabora/code:24.04.13.3.1"
    valkey    = "docker.io/valkey/valkey:8.1-alpine"
  }
}

job "nextcloud" {
  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
    weight    = 100
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "ambi"
    weight    = 50
  }

  group "nextcloud" {
    network {
      port "server" {
        to           = 80
        host_network = "private"
      }

      port "push" {
        to           = 7867
        host_network = "private"
      }

      port "collabora" {
        to           = 9980
        host_network = "private"
      }
    }

    task "server" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        cpu        = 2048
        memory_max = 4096
      }

      service {
        name         = "nextcloud"
        port         = "server"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file("config/database.config.php")
        destination = "local/database.config.php"
        uid         = 1000
        gid         = 1000
      }

      template {
        data        = file(".env-app")
        destination = ".env-app"
        env         = true
      }

      config {
        image  = "${local.image.nextcloud}"
        ports  = ["server"]
        userns = "keep-id"

        sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = "80"
        }

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/database.config.php:/var/www/html/config/database.config.php",
          "${local.strg}/config/config.php:/var/www/html/config/config.php",
          "${local.strg}/config/www2.conf:/usr/local/etc/php-fpm.d/www2.conf",
          "${local.strg}/config/nextcloud.ini:/usr/local/etc/php/conf.d/nextcloud.ini",
          "${local.strg}/config/redis-session.ini:/usr/local/etc/php/conf.d/redis-session.ini",
          "${local.strg}/data:/var/www/html",
          "${local.sock}:/tmp/sock",
          "${local.crypt}/nextcloud/antsva:/var/www/html/data/antsva",
          "${local.crypt}/nextcloud/amabilis:/var/www/html/data/amabilis",
          "${local.crypt}/nextcloud/jowl:/var/www/html/data/jowl",
        ]
      }
    }

    task "cron" {
      driver = "podman"
      user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file("config/cron.sh")
        destination = "/local/cron.sh"
        perms       = 755
        uid         = 1000
        gid         = 1000
      }

      template {
        data        = file("config/database.config.php")
        destination = "local/database.config.php"
        uid         = 1000
        gid         = 1000
      }

      template {
        data        = file(".env-app")
        destination = ".env-app"
        env         = true
      }

      config {
        image      = "${local.image.nextcloud}"
        entrypoint = ["/local/cron.sh"]
        userns     = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/database.config.php:/var/www/html/config/database.config.php",
          "${local.strg}/config/config.php:/var/www/html/config/config.php",
          "${local.strg}/data:/var/www/html",
          "${local.sock}:/tmp/sock",
        ]
      }
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = <<-EOF
          port 0
          bind 127.0.0.1
          unixsocket /tmp/sock/redis.sock
          unixsocketperm 770
          save ""
        EOF
        destination = "/local/redis.conf"
      }

      config {
        image  = "${local.image.valkey}"
        userns = "keep-id"
        args = [
          "/local/redis.conf"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock",
        ]
      }
    }

    task "push" {
      driver = "podman"
      user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      service {
        name         = "nextcloud-push"
        port         = "push"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file(".env-push")
        destination = ".env-push"
        env         = true
      }

      config {
        image  = "${local.image.nextcloud}"
        ports  = ["push"]
        userns = "keep-id"

        entrypoint = [
          "/local/notify_push",
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data/custom_apps/notify_push/bin/${attr.kernel.arch}/notify_push:/local/notify_push",
          "${local.sock}:/tmp/sock",
        ]
      }
    }

    task "collabora" {
      driver = "podman"

      resources {
        memory_max = 4096
      }

      service {
        name         = "collabora"
        port         = "collabora"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env-collabora")
        destination = ".env-collabora"
        env         = true
      }

      config {
        image = "${local.image.collabora}"
        ports = ["collabora"]

        logging = {
          driver = "journald"
        }
      }
    }
  }
}
