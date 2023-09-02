locals {
  strg = pathexpand("~/cld/caddy")
  log  = pathexpand("~/log/caddy")
}

job "caddy" {
  group "caddy" {
    count = 3

    constraint {
      attribute = "${meta.ingress}"
      value     = "true"
    }

    constraint {
      distinct_hosts = true
    }

    network {
      port "http" {
        static       = 80
        to           = 80
        host_network = "public"
      }

      port "https" {
        static       = 443
        to           = 443
        host_network = "public"
      }

      port "mail-1" {
        static       = 25
        to           = 25
        host_network = "public"
      }

      port "mail-2" {
        static       = 465
        to           = 465
        host_network = "public"
      }

      port "mail-3" {
        static       = 993
        to           = 993
        host_network = "public"
      }

      port "dot" {
        static       = 853
        to           = 853
        host_network = "public"
      }

      port "mc" {
        static       = 37663
        to           = 37663
        host_network = "public"
      }

      port "reverse-proxy" {
        to           = 2019
        host_network = "private"
      }

      port "l4-proxy" {
        to           = 2019
        host_network = "private"
      }
    }

    task "reverse-proxy" {
      driver = "docker"

      service {
        name     = "reverse-proxy-${attr.unique.hostname}"
        port     = "reverse-proxy"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("Caddyfile.tpl")
        destination = "/local/Caddyfile"
        change_mode = "script"
        change_script {
          command = "caddy"
          args    = ["reload", "--config", "/local/Caddyfile", "--adapter", "caddyfile"]
        }
      }

      config {
        image = "ghcr.io/cycneuramus/caddy:latest"
        ports = ["http", "https", "reverse-proxy"]

        entrypoint = [
          "caddy", "run", "--config", "/local/Caddyfile", "--adapter", "caddyfile"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/GeoLite2-Country.mmdb"
          target = "/etc/caddy/GeoLite2-Country.mmdb"
        }

        mount {
          type   = "bind"
          source = "${local.log}"
          target = "/var/log"
        }
      }
    }

    task "l4-proxy" {
      driver = "docker"

      service {
        name     = "l4-proxy-${attr.unique.hostname}"
        port     = "l4-proxy"
        provider = "nomad"
        tags     = ["private"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("caddy.json.tpl")
        destination = "/local/caddy.json"
        change_mode = "script"
        change_script {
          command = "caddy"
          args    = ["reload", "--config", "/local/caddy.json"]
        }
      }

      config {
        image = "ghcr.io/cycneuramus/caddy:latest"
        ports = ["mail-1", "mail-2", "mail-3", "dot", "mc", "l4-proxy"]

        entrypoint = [
          "caddy", "run", "--config", "/local/caddy.json"
        ]
      }
    }
  }

  group "redis" {
    count = 1

    constraint {
      attribute = "${meta.performance}"
      value     = "high"
    }

    network {
      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    service {
      name     = "caddy-redis"
      port     = "redis"
      provider = "nomad"
      tags     = ["private", "monitor"]
    }

    task "redis" {
      driver = "docker"
      user   = "1000:1000"

      config {
        image = "redis:alpine"
        ports = ["redis"]

        command = "redis-server"
        args = [
          "--save", "60", "1",
          "--loglevel", "warning"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/redis"
          target = "/data"
        }
      }
    }
  }
}
