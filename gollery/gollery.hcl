locals {
  nas   = "/mnt/nas/apps"
  image = "ghcr.io/cycneuramus/ifexifextract@sha256:f887aaad526d77d5c663f43cce760a04eb795ee96ae152c371ead27001eb3d3c"
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
          "${local.nas}/nextcloud/webroot/data/antsva/files/Bilder:/home/extractor/src",
          "${local.nas}/gollery:/home/extractor/data"
        ]
      }
    }
  }
}
