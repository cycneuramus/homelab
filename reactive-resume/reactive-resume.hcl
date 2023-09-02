locals {
  strg = pathexpand("~/cld/resume")
}

job "resume" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "resume" {
    count = 1

    network {
      port "frontend" {
        to           = 3000
        host_network = "private"
      }

      port "backend" {
        to           = 3100
        host_network = "private"
      }

      port "db" {
        to           = 5432
        host_network = "private"
      }
    }

    task "frontend" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "resume"
        port     = "frontend"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "amruthpillai/reactive-resume:client-latest"
        ports = ["frontend"]
      }
    }

    task "backend" {
      driver = "docker"

      resources {
        memory_max = 2048
      }

      service {
        name     = "resume-backend"
        port     = "backend"
        provider = "nomad"
        tags     = ["local", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "amruthpillai/reactive-resume:server-latest"
        ports = ["backend"]
      }
    }

    task "db" {
      driver = "docker"
      user   = "1000:1000"

      service {
        name     = "resume-db"
        port     = "db"
        provider = "nomad"
        tags     = ["private", "monitor"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "postgres:15"
        ports = ["db"]

        mount {
          type   = "bind"
          source = "${local.strg}/db"
          target = "/var/lib/postgresql/data"
        }
      }
    }
  }
}
