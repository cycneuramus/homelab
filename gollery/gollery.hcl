locals {
  nas   = "/mnt/nas/apps"
  image = "ghcr.io/cycneuramus/ifexifextract:latest"
}

job "gollery" {
  type = "batch"

  periodic {
    crons            = ["@daily"]
    prohibit_overlap = true
  }

  group "gollery" {
    task "extractor" {
      driver = "podman"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image   = "${local.image}"
        command = "extract"

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.nas}/nextcloud/data/webroot/data/antsva/files/Bilder:/home/extractor/src",
          "${local.nas}/gollery:/home/extractor/data"
        ]
      }
    }
  }
}
