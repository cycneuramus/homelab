locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:c04e19b0d6f2bfdfb1caa3ea133ff4bdab5f24bc7cc98b64060ca1204ada8a6b"
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
