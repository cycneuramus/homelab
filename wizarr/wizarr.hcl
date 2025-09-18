locals {
  strg  = "/mnt/jfs/wizarr"
  image = "ghcr.io/wizarrrr/wizarr:v2025.9.4"
}

job "wizarr" {
  group "wizarr" {
    network {
      port "http" {
        to           = 5690
        host_network = "private"
      }
    }

    task "wizarr" {
      driver = "podman"
      # user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "wizarr"
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
        data        = file("entrypoint.sh")
        destination = "/local/entrypoint.sh"
        perms       = 755
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        command = "/local/entrypoint.sh"
        args = [
          "uv", "run", "--frozen", "--no-dev", "gunicorn",
          "--config", "gunicorn.conf.py",
          "--bind", "0.0.0.0:5690",
          "--umask", "007",
          "run:app"
        ]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/data/database",
          "${local.strg}/cache:/data/.cache"
        ]
      }
    }
  }
}
