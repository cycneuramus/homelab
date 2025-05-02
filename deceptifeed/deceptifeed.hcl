locals {
  strg  = "/mnt/jfs/deceptifeed"
  image = "docker.io/deceptifeed/server:0.63.0"
}

job "deceptifeed" {
  group "deceptifeed" {
    count = 3

    constraint {
      attribute = "${meta.ingress}"
      value     = "true"
    }

    constraint {
      distinct_hosts = true
    }

    network {
      port "ssh" {
        static       = 22
        to           = 22
        host_network = "public"
      }

      port "http" {
        static       = 8080
        to           = 8080
        host_network = "public"
      }

      port "https" {
        static       = 8443
        to           = 8443
        host_network = "public"
      }

      port "admin" {
        static       = 9000
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
        name         = "honeypot"
        port         = "admin"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
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

      # template {
      #   data        = <<-EOF
      #     #!/bin/sh
      #
      #     vip="192.168.1.200"
      #     iface=$(ip -o addr | awk -v vip="$vip" '$0 ~ vip {print $2; exit}')
      #
      #     if [ -z "$iface" ]; then
      #       echo "Virtual IP not found on any interface. Sleeping..."
      #       sleep infinity
      #     else
      #       echo "Virtual IP found on interface $iface. Starting Deceptifeed..."
      #       exec /deceptifeed -config /local/config.xml
      #     fi
      #   EOF
      #   destination = "/local/entrypoint.sh"
      #   perms       = "755"
      # }

      config {
        image        = "${local.image}"
        ports        = ["ssh", "http", "https", "admin"]
        network_mode = "host"

        userns = "keep-id"

        cpu_hard_limit = true

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

    task "deceptimeed" {
      driver = "raw_exec"

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("entrypoint.sh")
        destination = "local/entrypoint.sh"
        perms       = 755
      }

      config {
        command = "/local/entrypoint.sh"
      }
    }
  }
}
