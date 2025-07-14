locals {
  image = "docker.io/andrewsav/terraforming-mars@sha256:b453498298b3527dd4763d4cbc27f4f10d77721904f39c06cfe2eee00b5cd141"
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

        tmpfs = ["/usr/src/app/db"]
      }
    }
  }
}
