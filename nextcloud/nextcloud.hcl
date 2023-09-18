locals {
  strg = pathexpand("~/cld/nextcloud")

  cloud_vol = {
    userdata-1 = "nextcloud_userdata-1"
    userdata-2 = "nextcloud_userdata-2"
    userdata-3 = "nextcloud_userdata-3"
  }

  cleanup_args = concat(["volume", "rm"], values("${local.cloud_vol}"))
}

job "nextcloud" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.storage}"
    value     = "large"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
    weight    = 100
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "home"
    weight    = 25
  }

  group "nextcloud" {
    count = 1

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

      port "db" {
        to           = 5432
        host_network = "private"
      }
    }

    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      config {
        command = "docker"
        args    = "${local.cleanup_args}"
      }
    }

    task "server" {
      driver = "docker"
      user   = "1000:1000"

      resources {
        cpu        = 1000
        memory_max = 4096
      }

      service {
        name     = "nextcloud"
        port     = "server"
        provider = "nomad"
        tags     = ["public"]
      }

      template {
        data        = file("env_server")
        destination = "env_server"
        env         = true
      }

      config {
        image = "nextcloud:27-apache"
        ports = ["server"]

        mount {
          type   = "bind"
          source = "${local.strg}/config/config.php"
          target = "/var/www/html/config/config.php"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config/www2.conf"
          target = "/usr/local/etc/php-fpm.d/www2.conf"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config/nextcloud.ini"
          target = "/usr/local/etc/php/conf.d/nextcloud.ini"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config/redis-session.ini"
          target = "/usr/local/etc/php/conf.d/redis-session.ini"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/var/www/html"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.userdata-1}"
          target = "/var/www/html/data/user-1"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-1"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.userdata-2}"
          target = "/var/www/html/data/user-2"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-2"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.userdata-3}"
          target = "/var/www/html/data/user-3"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-3"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }
      }
    }

    task "cron" {
      driver = "docker"
      user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file("config/cron.sh")
        destination = "/local/cron.sh"
        perms       = "755"
        uid         = 1000
        gid         = 1000
      }

      config {
        image      = "nextcloud:27-apache"
        entrypoint = ["/local/cron.sh"]

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/var/www/html"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config/config.php"
          target = "/var/www/html/config/config.php"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }
      }
    }

    task "db" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "nextcloud-db"
        port     = "db"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        data        = file("env_db")
        destination = "env_db"
        env         = true
      }

      config {
        image = "postgres:15"
        ports = ["db"]

        command = "postgres"
        args = [
          "-c", "unix_socket_directories=/var/run/postgresql,/tmp/sock"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/db"
          target = "/var/lib/postgresql/data"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }
      }
    }

    task "redis" {
      driver = "docker"
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
        image = "redis:alpine"

        command = "redis-server"
        args = [
          "/local/redis.conf"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }
      }
    }

    task "push" {
      driver = "docker"
      user   = "1000:1000"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      service {
        name     = "nextcloud-push"
        port     = "push"
        provider = "nomad"
        tags     = ["private"]
      }

      env {
        LOG           = "info"
        NEXTCLOUD_URL = "http://${NOMAD_ADDR_server}"
      }

      config {
        image = "nextcloud:27-fpm-alpine"
        ports = ["push"]

        entrypoint = [
          "/var/www/html/custom_apps/notify_push/bin/x86_64/notify_push",
          "/var/www/html/config/config.php"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/config/config.php"
          target = "/var/www/html/config/config.php"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data"
          target = "/var/www/html"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }
      }
    }

    task "collabora" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "collabora"
        port     = "collabora"
        provider = "nomad"
        tags     = ["local"]
      }

      env {
        DONT_GEN_SSL_CERT = "1"
        dictionaries      = "en sv"
        extra_params      = "--o:ssl.enable=false --o:ssl.termination=true"
      }

      config {
        image = "collabora/code:latest"
        ports = ["collabora"]
      }
    }
  }
}

