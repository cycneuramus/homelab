locals {
  image = "docker.io/mirotalk/p2p@sha256:91d27d1dc76749f99ecab87cc64f912153f8ee04d298329da222c8a34a76677d"
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
