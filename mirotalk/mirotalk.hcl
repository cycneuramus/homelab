locals {
  image = "docker.io/mirotalk/p2p@sha256:8543aeb68e4899272a8d2435faaef4bec85a906286c2fe99cebd8b1818a098dd"
}

job "mirotalk" {
  group "mirotalk" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "mirotalk" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "meet"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.js")
        destination = "/local/config.js"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        volumes = [
          "local/config.js:/src/app/src/config.js:ro"
        ]
      }
    }
  }
}
