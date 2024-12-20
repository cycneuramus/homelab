locals {
  strg = "/mnt/jfs/resume"
}

job "resume" {
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "!="
    value     = "arm64"
  }

  group "resume" {
    network {
      port "frontend" {
        to           = 3000
        host_network = "private"
      }

      port "backend" {
        to           = 3100
        host_network = "private"
      }
    }

    task "frontend" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "resume"
        port         = "frontend"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "amruthpillai/reactive-resume:client-latest"
        ports = ["frontend"]

        logging = {
          driver = "journald"
        }
      }
    }

    task "backend" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "resume-backend"
        port         = "backend"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "amruthpillai/reactive-resume:server-latest"
        ports = ["backend"]

        logging = {
          driver = "journald"
        }

        volumes = ["${local.strg}/uploads:/app/server/dist/assets/uploads"]
      }
    }
  }
}
