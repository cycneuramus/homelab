locals {
  sock  = pathexpand("~/cld/immich/sock")
  strg  = "/mnt/jfs/immich"
  crypt = "/mnt/crypt"

  image = {
    immich           = "ghcr.io/immich-app/immich-server:v1.134.0"
    machine-learning = "ghcr.io/immich-app/immich-machine-learning:v1.133.1"
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
          "${local.strg}/thumbs:/usr/src/app/upload/thumbs",
          "${local.crypt}/immich/upload:/usr/src/app/upload/upload",
          "${local.crypt}/immich/profile:/usr/src/app/upload/profile",
          "${local.crypt}/immich/library:/usr/src/app/upload/library",
          "${local.crypt}/immich/backups:/usr/src/app/upload/backups",
          "${local.crypt}/immich/encoded-video:/usr/src/app/upload/encoded-video",
          "${local.crypt}/nextcloud/antsva/files/Bilder:/libraries/user-1:ro",
          "${local.crypt}/gollery:/libraries/user-3:ro",
        ]
      }
    }

    task "machine-learning" {
      driver = "podman"

      resources {
        memory_max = 4096
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
          "${local.strg}/cache:/cache",
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
