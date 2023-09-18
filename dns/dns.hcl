locals {
  strg = pathexpand("~/cld/dns")
}

job "dns" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  constraint {
    attribute = "${meta.datacenter}"
    operator  = "!="
    value     = "ocl"
  }

  group "dns" {
    count = 1

    network {
      port "adguard" {
        to           = 3000
        host_network = "private"
      }

      port "dns" {
        to           = 853
        host_network = "private"
      }

      port "unbound" {
        to           = 5053
        host_network = "private"
      }
    }

    task "unbound" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      service {
        name     = "unbound"
        port     = "unbound"
        provider = "nomad"
        tags     = ["private"]
      }

      config {
        image = "crazymax/unbound"
        ports = ["unbound"]
      }
    }

    task "adguard" {
      driver = "docker"

      service {
        name     = "adguard"
        port     = "adguard"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        data        = file("adguard-config.yml.tpl")
        destination = "/local/adguard-config.yml"
      }

      env {
        TZ = "Europe/Stockholm"
      }

      config {
        image = "adguard/adguardhome"
        ports = ["adguard"]

        entrypoint = [
          "/opt/adguardhome/AdGuardHome",
          "--no-check-update",
          "-c", "/local/adguard-config.yml",
          "-w", "/opt/adguardhome/work"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/conf"
          target = "/opt/adguardhome/conf"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/work"
          target = "/opt/adguardhome/work"
        }

        mount {
          type     = "bind"
          source   = "${local.strg}/cert"
          target   = "/opt/adguardhome/cert"
          readonly = true
        }
      }
    }
  }

  group "cert" {
    count = 1

    task "caddy" {
      driver = "docker"

      template {
        source      = "${local.strg}/env_caddy"
        destination = "env_caddy"
        env         = "true"
      }

      config {
        image = "ghcr.io/cycneuramus/caddy:latest"

        mount {
          type   = "bind"
          source = "${local.strg}/caddy"
          target = "/data/caddy"
        }
      }
    }
  }
}
