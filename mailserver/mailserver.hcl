locals {
  strg = pathexpand("~/cld/mailserver")
  cert = pathexpand("~/cld/dns/caddy/certificates/acme-v02.api.letsencrypt.org-directory")
}

job "mailserver" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "mailserver" {
    count = 1

    network {
      port "mailserver-25" {
        to           = 25
        host_network = "private"
      }
      port "mailserver-465" {
        to           = 465
        host_network = "private"
      }
      port "mailserver-10993" {
        to           = 10993
        host_network = "private"
      }
    }

    task "mailserver" {
      driver = "docker"

      service {
        name     = "mailserver-25"
        port     = "mailserver-25"
        provider = "nomad"
        tags     = ["private"]
      }

      service {
        name     = "mailserver-465"
        port     = "mailserver-465"
        provider = "nomad"
        tags     = ["private"]
      }

      service {
        name     = "mailserver-10993"
        port     = "mailserver-10993"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        source      = "${local.strg}/.env"
        destination = "env"
        env         = true
      }

      config {
        image = "ghcr.io/docker-mailserver/docker-mailserver:latest"
        ports = ["mailserver-25", "mailserver-465", "mailserver-10993"]

        mount {
          type   = "bind"
          source = "${local.strg}/data/mail-data"
          target = "/var/mail"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data/mail-logs/mail.log"
          target = "/var/log/mail/mail.log"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/data/config"
          target = "/tmp/docker-mailserver"
        }

        mount {
          type     = "bind"
          source   = "${local.cert}"
          target   = "/etc/cert"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "/etc/localtime"
          target   = "/etc/localtime"
          readonly = true
        }
      }
    }
  }
}
