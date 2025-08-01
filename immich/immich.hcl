locals {
  sock = pathexpand("~/cld/immich/sock")
  nas  = "/mnt/nas/apps"

  image = {
    immich           = "ghcr.io/immich-app/immich-server:v1.136.0"
    machine-learning = "ghcr.io/immich-app/immich-machine-learning:v1.136.0"
    valkey           = "docker.io/valkey/valkey:8.1-alpine"
  }
}

job "immich" {
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

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "horreum"
    weight    = -100
  }

  update {
    canary       = 1
    auto_promote = true
    auto_revert  = true
  }

  group "immich" {
    network {
      port "server" {
        to           = 2283
        host_network = "private"
      }

      port "machinelearning" {
        to           = 3003
        host_network = "private"
      }

      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    task "server" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "immich"
        port         = "server"
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
        image = "${local.image.immich}"
        ports = ["server"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock",
          "${local.nas}/immich/thumbs:/usr/src/app/upload/thumbs",
          "${local.nas}/immich/upload:/usr/src/app/upload/upload",
          "${local.nas}/immich/profile:/usr/src/app/upload/profile",
          "${local.nas}/immich/library:/usr/src/app/upload/library",
          "${local.nas}/immich/backups:/usr/src/app/upload/backups",
          "${local.nas}/immich/encoded-video:/usr/src/app/upload/encoded-video",
          "${local.nas}/nextcloud/data/webroot/data/antsva/files/Bilder:/libraries/user-1:ro",
          "${local.nas}/gollery:/libraries/user-3:ro",
        ]
      }
    }

    task "machine-learning" {
      driver = "podman"

      resources {
        memory_max = 8092
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image.machine-learning}"
        ports = ["machinelearning"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock",
          "${local.nas}/immich/cache:/cache",
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
          "${local.sock}:/tmp/sock"
        ]
      }
    }
  }
}
