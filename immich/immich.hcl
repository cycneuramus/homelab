locals {
  sock      = pathexpand("~/cld/immich/sock")
  strg      = "/mnt/jfs/immich"
  mnt-crypt = "/mnt/crypt"

  version = {
    immich = "v1.123.0"
    valkey = "7.2-alpine"
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

      # port "db" {
      #   to           = 5432
      #   host_network = "private"
      # }
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
        image = "ghcr.io/immich-app/immich-server:${local.version.immich}"
        ports = ["server"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock",
          "${local.strg}/thumbs:/usr/src/app/upload/thumbs",
          "${local.mnt-crypt}/immich/upload:/usr/src/app/upload/upload",
          "${local.mnt-crypt}/immich/profile:/usr/src/app/upload/profile",
          "${local.mnt-crypt}/immich/library:/usr/src/app/upload/library",
          "${local.mnt-crypt}/immich/backups:/usr/src/app/upload/backups",
          "${local.mnt-crypt}/immich/encoded-video:/usr/src/app/upload/encoded-video",
          "${local.mnt-crypt}/nextcloud/antsva/files/Bilder:/libraries/user-1:ro",
          "${local.mnt-crypt}/gollery:/libraries/user-3:ro",
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
        image = "ghcr.io/immich-app/immich-machine-learning:${local.version.immich}"
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
        image  = "valkey/valkey:${local.version.valkey}"
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

    # task "db" {
    #   driver = "podman"
    #   user   = "1000:1000"
    #
    #   resources {
    #     memory_max = 2048
    #   }
    #
    #   lifecycle {
    #     hook = "prestart"
    #     sidecar = true
    #   }
    #
    #   service {
    #     name     = "immich-db"
    #     port     = "db"
    #     provider = "nomad"
    #     address_mode = "host"
    #     tags     = ["private"]
    #   }
    #
    #   template {
    #     data        = file("env_db")
    #     destination = "env_db"
    #     env         = true
    #   }
    #
    #   config {
    #     image = "tensorchord/pgvecto-rs:pg15-v0.2.0"
    #     ports = ["db"]
    #
    #     userns = "keep-id"
    #
    #     logging = {
    #       driver = "journald"
    #     }
    #
    #     # command = "postgres"
    #     # args = [
    #     #   "-c", "unix_socket_directories=/var/run/postgresql,/tmp/sock"
    #     # ]
    #
    #     volumes = [
    #       "${local.db}:/var/lib/postgresql/data"
    #     ]
    # }
  }
}
