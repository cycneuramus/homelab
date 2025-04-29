locals {
  image = "ghcr.io/ituoga/coredns-nomad:v0.1.0"
}

job "coredns" {
  type = "service"

  group "coredns" {
    count = 3

    constraint {
      attribute = "${meta.ingress}"
      value     = "true"
    }

    constraint {
      distinct_hosts = true
    }

    network {
      port "dns" {
        static = 1053
      }
    }

    task "coredns" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image}"
        ports = ["dns"]

        args = ["-conf", "/local/Corefile", "-dns.port", "1053"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }
      }

      service {
        name         = "hostmaster"
        provider     = "nomad"
        port         = "dns"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data          = file("Corefile.tpl")
        destination   = "/local/Corefile"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
