locals {
  strg  = "/mnt/jfs/deceptifeed"
  image = "docker.io/deceptifeed/server:0.66.0"
}

job "deceptifeed" {
  # group "deceptimeed" {
  #   count = 3
  #
  #   constraint {
  #     attribute = "${meta.ingress}"
  #     value     = "true"
  #   }
  #
  #   constraint {
  #     distinct_hosts = true
  #   }
  #
  #   task "deceptimeed" {
  #     driver = "raw_exec"
  #
  #     template {
  #       data        = file(".env")
  #       destination = "env"
  #       env         = true
  #     }
  #
  #     template {
  #       data        = file("entrypoint.sh")
  #       destination = "local/entrypoint.sh"
  #       perms       = 755
  #     }
  #
  #     config {
  #       command = "/local/entrypoint.sh"
  #     }
  #   }
  # }

  group "deceptifeed" {
    network {
      port "ssh" {
        to           = 2222
        host_network = "private"
      }

      port "http" {
        to           = 8080
        host_network = "private"
      }

      port "https" {
        to           = 8443
        host_network = "private"
      }

      port "admin" {
        to           = 9000
        host_network = "private"
      }
    }

    task "deceptifeed" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        cpu        = 100
        memory_max = 512
      }

      service {
        name         = "honeypot-ssh"
        port         = "ssh"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "honeypot-http"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "honeypot-https"
        port         = "https"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["private"]
      }

      service {
        name         = "honeypot"
        port         = "admin"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:security"]
      }

      template {
        data        = file("config.xml")
        destination = "/local/config.xml"
        uid         = 1000
        gid         = 1000
      }

      template {
        data        = file("whitelist")
        destination = "/local/whitelist"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image}"
        ports = ["ssh", "http", "https", "admin"]

        cpu_hard_limit = true

        userns = "keep-id"

        entrypoint = "/deceptifeed"
        args       = ["-config", "/local/config.xml"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/data"
        ]
      }
    }
  }
}
