locals {
  strg = {
    slskd   = "/mnt/jfs/soulseek"
    betanin = "/mnt/jfs/betanin"
    music   = "/mnt/nas/apps/navidrome/music"
  }

  image = {
    slskd   = "ghcr.io/slskd/slskd:0.23.2"
    betanin = "docker.io/sentriz/betanin:v0.5.6"
  }
}

job "soulseek" {
  group "soulseek" {
    network {
      port "slskd" {
        to           = 5030
        host_network = "private"
      }

      port "betanin" {
        to           = 9393
        host_network = "private"
      }
    }

    task "slskd" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "soulseek"
        port         = "slskd"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config.yml")
        destination = "/local/config.yml"
      }

      template {
        data        = file("auto-import.sh.tpl")
        destination = "/local/auto-import.sh"
        perms       = 755
      }

      config {
        image = "${local.image.slskd}"
        ports = ["slskd"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg.music}:/music",
          "${local.strg.slskd}:/app",
        ]
      }
    }

    task "betanin" {
      driver = "podman"

      service {
        name         = "beets"
        port         = "betanin"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        UID = "0"
        GID = "0"
      }

      config {
        image = "${local.image.betanin}"
        ports = ["betanin"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg.betanin}/data:/b/.local/share/betanin",
          "${local.strg.betanin}/config:/b/.config/betanin",
          "${local.strg.betanin}/beets:/b/.config/beets",
          "${local.strg.slskd}/downloads:/downloads",
          "${local.strg.music}:/music",
        ]
      }
    }
  }
}
