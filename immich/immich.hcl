locals {
  strg      = pathexpand("~/cld/immich")
  cloud_vol = "immich"
}

job "immich" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "immich" {
    count = 1

    network {
      port "server" {
        to           = 3001
        host_network = "private"
      }

      port "web" {
        to           = 3000
        host_network = "private"
      }

      port "ingress" {
        to           = 8080
        host_network = "private"
      }

      port "machinelearning" {
        to           = 3003
        host_network = "private"
      }

      port "typesense" {
        to           = 8108
        host_network = "private"
      }

      port "redis" {
        to           = 6379
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
        args    = ["volume", "rm", "${local.cloud_vol}"]
      }
    }

    task "server" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "immich-server"
        port     = "server"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "ghcr.io/immich-app/immich-server:release"
        force_pull = true
        ports = ["server"]

        command = "start-server.sh"

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol}"
          target = "/usr/src/app/upload"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/immich"
              }
            }
          }
        }
      }
    }

    task "microservices" {
      driver = "docker"

      resources {
        memory_max = 6000
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image   = "ghcr.io/immich-app/immich-server:release"
        force_pull = true

        command = "start-microservices.sh"

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol}"
          target = "/usr/src/app/upload"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/immich"
              }
            }
          }
        }
      }
    }

    task "machine-learning" {
      driver = "docker"

      resources {
        memory_max = 6000
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "ghcr.io/immich-app/immich-machine-learning:release"
        force_pull = true
        ports = ["machinelearning"]

        mount {
          type   = "bind"
          source = "${local.strg}/sock"
          target = "/tmp/sock"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/cache"
          target = "/cache"
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol}"
          target = "/usr/src/app/upload"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/immich"
              }
            }
          }
        }
      }
    }

    task "web" {
      driver = "docker"

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "ghcr.io/immich-app/immich-web:release"
        force_pull = true
        ports = ["web"]
      }
    }

    task "ingress" {
      driver = "docker"

      service {
        name     = "immich"
        port     = "ingress"
        provider = "nomad"
        tags     = ["public"]
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "ghcr.io/immich-app/immich-proxy:release"
        force_pull = true
        ports = ["ingress"]
      }
    }

    task "typesense" {
      driver = "docker"

      resources {
        memory_max = 6000
      }

      template {
        data        = file("env_app")
        destination = "env_app"
        env         = true
      }

      config {
        image = "typesense/typesense:0.24.0"
        ports = ["typesense"]

        mount {
          type   = "bind"
          source = "${local.strg}/typesense"
          target = "/data"
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
  }
}
