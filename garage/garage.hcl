locals {
  strg  = pathexpand("~/.local/share/s3")
  image = "docker.io/dxflrs/garage:v2.1.0"
}

job "garage" {
  group "garage" {
    count = 3

    constraint {
      attribute = "${meta.s3}"
      value     = "true"
    }

    constraint {
      distinct_hosts = true
    }

    update {
      max_parallel     = 1
      min_healthy_time = "15s"
      healthy_deadline = "1m"
      auto_revert      = true
    }

    network {
      port "s3" {
        to           = 3900
        static       = 3900
        host_network = "private"
      }

      port "rpc" {
        to           = 3901
        static       = 3901
        host_network = "private"
      }

      port "admin" {
        to           = 3903
        static       = 3903
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOF
          #!/bin/bash
          mkdir -p ${local.strg}/{meta,data}
        EOF
        destination = "local/preflight.sh"
        perms       = 755
      }

      config {
        command = "local/preflight.sh"
      }
    }

    task "garage" {
      driver = "podman"

      kill_signal  = "SIGINT"
      kill_timeout = "30s"

      resources {
        memory_max = 4096
      }

      service {
        name         = "s3-${attr.unique.hostname}"
        port         = "s3"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.toml.tpl")
        destination = "local/garage.toml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image}"
        ports = ["admin", "rpc", "s3"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/meta:/var/lib/garage/meta",
          "${local.strg}/data:/var/lib/garage/data",
        ]
      }
    }
  }
}
