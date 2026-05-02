locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:cebab2bb527d3de4554d622d06eb2b771f082e85abfdfdde9c6e995b9eb40678"
  strg  = "..${NOMAD_ALLOC_DIR}/data"
}

job "terraforming-mars" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "terraforming-mars" {
    network {
      port "http" {
        to           = 8765
        host_network = "private"
      }
    }

    task "terraforming-mars" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "tm"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      env {
        NODE_ENV = "production"
        PORT     = "8765"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        force_pull = true

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/usr/src/app/db"
        ]
      }
    }
  }
}
