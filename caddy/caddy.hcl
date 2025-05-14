locals {
  log   = pathexpand("~/log/caddy")
  crypt = "/mnt/crypt"

  image = {
    caddy  = "ghcr.io/cycneuramus/containers:caddy"
    valkey = "docker.io/valkey/valkey:8.1-alpine"
  }
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

    update {
      max_parallel     = 1
      min_healthy_time = "5s"
      healthy_deadline = "1m"
      auto_revert      = true
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

      port "smtp" {
        static       = 25
        to           = 25
        host_network = "public"
      }

      port "smtps" {
        static       = 465
        to           = 465
        host_network = "public"
      }

      port "imaps" {
        static       = 993
        to           = 993
        host_network = "public"
      }

      port "admin" {
        static       = 2019
        to           = 2019
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
          #!/bin/sh
          {{ range nomadService "caddy-redis" }}
          until nc -z {{ .Address }} {{ .Port }}; do sleep 1; done
          {{ end -}}
        EOF
        destination = "local/preflight.sh"
        perms       = 755
      }

      config {
        command = "local/preflight.sh"
      }
    }

    task "caddy" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "caddy-${attr.unique.hostname}"
        port         = "admin"
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
        data        = file("Caddyfile.tpl")
        destination = "/local/Caddyfile"
        change_mode = "script"
        change_script {
          command = "caddy"
          args    = ["reload", "--config", "/local/Caddyfile", "--adapter", "caddyfile"]
        }
      }

      config {
        image = "${local.image.caddy}"
        ports = [
          "http",
          "https",
          "smtp",
          "smtps",
          "imaps",
          "admin"
        ]

        force_pull = true

        network_mode = "host"

        entrypoint = [
          "caddy", "run", "--config", "/local/Caddyfile", "--adapter", "caddyfile"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.log}:/var/log"
        ]
      }
    }
  }

  group "redis" {
    count = 1

    network {
      port "redis" {
        to           = 6379
        host_network = "private"
      }
    }

    service {
      name         = "caddy-redis"
      port         = "redis"
      provider     = "nomad"
      address_mode = "host"
      tags         = ["private"]
    }

    task "redis" {
      driver = "podman"
      user   = "1000:1000"

      config {
        image = "${local.image.valkey}"
        ports = ["redis"]

        userns = "keep-id"

        args = [
          "--save", "60", "1"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.crypt}/caddy/redis:/data",
        ]
      }
    }
  }
}
