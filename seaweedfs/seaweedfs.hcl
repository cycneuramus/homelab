locals {
  strg = pathexpand("~/.local/share/seaweedfs")
  masters = "10.10.10.10:9333,10.10.10.11:9333,10.10.10.12:9333"
}

job "seaweedfs" {
  group "seaweedfs" {
    count = 3

    constraint {
      attribute = "${meta.storage}"
      value     = "large"
    }

    update {
      max_parallel = 1
      stagger      = "2m"
    }

    migrate {
      min_healthy_time = "2m"
    }

    network {
      port "s3" {
        to           = 8333
        static       = 8333
        host_network = "private"
      }

      port "master_http" {
        to           = 9333
        static       = 9333
        host_network = "private"
      }

      port "master_grpc" {
        to           = 19333
        static       = 19333
        host_network = "private"
      }

      port "filer_http" {
        to           = 8888
        static       = 8888
        host_network = "private"
      }

      port "filer_grpc" {
        to           = 18888
        static       = 18888
        host_network = "private"
      }

      port "volume_http" {
        to           = 8080
        static       = 8080
        host_network = "private"
      }

      port "volume_grpc" {
        to           = 18080
        static       = 18080
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"
      user   = "antsva"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      template {
        data        = <<-EOF
          #!/bin/bash
          mkdir -p ${local.strg}/{master,filer,volume}
        EOF
        destination = "local/preflight.sh"
        perms       = 755
      }

      config {
        command = "local/preflight.sh"
      }
    }

    task "master" {
      driver = "docker"
      user   = "1000:1000"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      service {
        name     = "seaweedfs-master-${attr.unique.hostname}"
        port     = "master_http"
        provider = "nomad"
        tags     = ["local"]
      }

      service {
        name     = "s3-${attr.unique.hostname}"
        port     = "s3"
        provider = "nomad"
        tags     = ["local"]
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["master_http", "master_grpc"]

        args = [
          "master",
          "-mdir=/data",
          "-defaultReplication=200",
          "-volumeSizeLimitMB=1024",
          "-garbageThreshold=0.0001",
          "-ip=${NOMAD_IP_master_http}",
          "-ip.bind=0.0.0.0",
          "-peers=${local.masters}",
          "-raftHashicorp",
          "-resumeState"
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/master"
          target = "/data"
        }
      }
    }

    task "filer" {
      driver = "docker"
      user   = "1000:1000"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      resources {
        memory_max = 1024
      }

      service {
        name     = "seaweedfs-filer-${attr.unique.hostname}"
        port     = "filer_http"
        provider = "nomad"
        tags     = ["local"]
      }

      template {
        data        = <<-EOF
          [leveldb3]
          enabled = true
          dir = "/data/filerdb"
        EOF
        destination = "local/filer.toml"
      }

      template {
        data        = file("s3.json")
        destination = "local/s3.json"
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["filer_http", "filer_grpc", "s3"]

        args = [
          "filer",
          "-master=${NOMAD_ADDR_master_http}",
          "-s3",
          "-s3.config=/local/s3.json",
          "-s3.allowEmptyFolder=true",
          "-webdav=false",
          "-defaultReplicaPlacement=200",
          "-dataCenter=${attr.unique.hostname}",
          "-ip=${NOMAD_IP_filer_http}",
          "-ip.bind=0.0.0.0",
        ]

        mount {
          type   = "bind"
          source = "local/filer.toml"
          target = "/etc/seaweedfs/filer.toml"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/filer"
          target = "/data/filerdb"
        }
      }
    }

    task "volume" {
      driver = "docker"
      user   = "1000:1000"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      resources {
        memory_max = 4096
      }

      service {
        name     = "seaweedfs-volume-${attr.unique.hostname}"
        port     = "volume_http"
        provider = "nomad"
        tags     = ["local"]
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["volume_http", "volume_grpc"]

        args = [
          "volume",
          "-mserver=${local.masters}",
          "-max=100",
          "-dir=/data",
          "-dataCenter=${attr.unique.hostname}",
          "-ip=${NOMAD_IP_volume_http}",
          "-ip.bind=0.0.0.0",
        ]

        mount {
          type   = "bind"
          source = "${local.strg}/volume"
          target = "/data"
        }
      }
    }
  }
}
