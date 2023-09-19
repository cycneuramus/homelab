locals {
  strg = pathexpand("~/cld/gollery")

  cloud_vol = {
    user-1    = "gollery_user-1"
    user-2    = "gollery_user-2"
    extracted = "gollery_extracted"
  }

  cleanup_args = concat(["volume", "rm"], values("${local.cloud_vol}"))
}

job "gollery" {
  type = "batch"

  periodic {
    cron             = "@daily"
    prohibit_overlap = true
  }

  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "gollery" {
    count = 1

    task "cleanup" {
      driver = "raw_exec"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      config {
        command = "docker"
        args    = "${local.cleanup_args}"
      }
    }

    task "extractor" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "docker"
      user   = "1000:1000"

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image   = "ghcr.io/cycneuramus/ifexifextract:latest"
        command = "extract"

        mount {
          type     = "volume"
          source   = "${local.cloud_vol.user-1}"
          target   = "/home/extractor/src"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-1/files/Bilder"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.extracted}"
          target = "/home/extractor/data"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/gollery"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }
      }
    }

    task "uploader" {
      driver = "docker"
      user   = "1000:1000"

      resources {
        memory_max = 2048
      }

      template {
        data        = file("upload.sh.tpl")
        destination = "/local/upload.sh"
        perms       = "755"
      }

      config {
        image      = "ghcr.io/immich-app/immich-server:release"
        entrypoint = ["/local/upload.sh"]

        mount {
          type     = "volume"
          source   = "${local.cloud_vol.user-1}"
          target   = "/user-1"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-1/files/Bilder"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type     = "volume"
          source   = "${local.cloud_vol.user-2}"
          target   = "/user-2"
          readonly = true
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/nextcloud/user-2/files/Bilder"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }

        mount {
          type   = "volume"
          source = "${local.cloud_vol.extracted}"
          target = "/extracted"
          volume_options {
            driver_config {
              name = "rclone"
              options {
                remote = "crypt:cld/gollery"
                uid    = "1000"
                gid    = "1000"
              }
            }
          }
        }
      }
    }
  }
}
