locals {
  strg    = pathexpand("~/.local/share/keydb")
  sock    = pathexpand("~/cld/keydb/sock")
  version = "alpine_x86_64_v6.3.3"
}

job "keydb" {
  group "keydb" {
    count = 3

    constraint {
      distinct_hosts = true
    }

    update {
      max_parallel     = 1
      min_healthy_time = "15s"
      healthy_deadline = "2m"
      auto_revert      = true
    }

    network {
      port "keydb" {
        to           = 16380
        static       = 16380
        host_network = "private"
      }
    }

    task "keydb" {
      driver = "podman"
      user   = "1000:1000"

      kill_timeout = "30s"

      resources {
        memory_max = 2048
      }

      service {
        name         = "keydb-${attr.unique.hostname}"
        port         = "keydb"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file("cfg-keydb.tpl")
        destination = "/local/keydb.conf"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "eqalpha/keydb:${local.version}"
        ports = ["keydb"]

        command = "keydb-server"
        args    = ["/local/keydb.conf"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.sock}:/tmp/sock",
          "${local.strg}:/data"
        ]
      }
    }
  }
}
