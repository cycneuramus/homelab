locals {
  strg  = "/mnt/jfs/arr"
  media = "/mnt/nas/media"
  dl    = pathexpand("~/dl")

  image = {
    sonarr   = "ghcr.io/linuxserver/sonarr:4.0.11"
    radarr   = "ghcr.io/linuxserver/radarr:5.17.2"
    bazarr   = "ghcr.io/linuxserver/bazarr:1.5.1"
    prowlarr = "ghcr.io/linuxserver/prowlarr:1.29.2"
    rdt      = "ghcr.io/rogerfar/rdtclient:2.0.93"
  }
}

job "arr" {
  group "arr" {
    network {
      port "sonarr" {
        to           = 8989
        host_network = "private"
      }

      port "radarr" {
        to           = 7878
        host_network = "private"
      }

      port "bazarr" {
        to           = 6767
        host_network = "private"
      }

      port "prowlarr" {
        to           = 9696
        host_network = "private"
      }

      port "rdt" {
        to           = 6500
        host_network = "private"
      }
    }

    task "sonarr" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 1024
      }

      service {
        name         = "sonarr"
        port         = "sonarr"
        address_mode = "host"
        provider     = "nomad"
        tags         = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      template {
        data        = file("config/sonarr-config.xml.tpl")
        destination = "/local/sonarr-config.xml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image.sonarr}"
        ports = ["sonarr"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/sonarr-config.xml:/config/config.xml",
          "${local.strg}/sonarr:/config",
          "${local.dl}:/downloads",
          "${local.media}:/mnt/cryptnas/media"
        ]
      }
    }

    task "radarr" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 1024
      }

      service {
        name         = "radarr"
        port         = "radarr"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      template {
        data        = file("config/radarr-config.xml.tpl")
        destination = "/local/radarr-config.xml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image.radarr}"
        ports = ["radarr"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/radarr-config.xml:/config/config.xml",
          "${local.strg}/radarr:/config",
          "${local.dl}:/downloads",
          "${local.media}:/mnt/cryptnas/media"
        ]
      }
    }

    task "bazarr" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "bazarr"
        port         = "bazarr"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file("config/bazarr.env")
        destination = "env"
        env         = true
      }

      template {
        data        = file("config/bazarr-config.yaml.tpl")
        destination = "/local/bazarr-config.yaml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image.bazarr}"
        ports = ["bazarr"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/bazarr-config.yaml:/config/config/config.yaml",
          "${local.strg}/bazarr:/config",
          "${local.media}:/mnt/cryptnas/media"
        ]
      }
    }

    task "prowlarr" {
      driver = "podman"
      user   = "0:0"

      resources {
        memory_max = 1024
      }

      service {
        name         = "prowlarr"
        port         = "prowlarr"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      template {
        data        = file("config/prowlarr-config.xml.tpl")
        destination = "/local/prowlarr-config.xml"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "${local.image.prowlarr}"
        ports = ["prowlarr"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/prowlarr-config.xml:/config/config.xml",
          "${local.strg}/prowlarr:/config",
        ]
      }
    }

    task "rdt" {
      driver = "podman"

      resources {
        memory_max = 2048
      }

      service {
        name         = "rdt"
        port         = "rdt"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        PUID = "0"
        PGID = "0"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "${local.image.rdt}"
        ports = ["rdt"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/rdt:/data/db",
          "${local.dl}:/data/downloads"
        ]
      }
    }
  }
}
