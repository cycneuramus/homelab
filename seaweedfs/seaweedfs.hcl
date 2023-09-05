locals {
  strg = pathexpand("~/.local/share/seaweedfs")
}

job "seaweedfs" {
  group "master" {
    count = 1

    constraint {
      attribute = "${meta.performance}"
      value     = "high"
    }

    update {
      max_parallel = 1
      stagger      = "2m"
    }

    migrate {
      min_healthy_time = "2m"
    }

    network {
      port "http" {
        to           = 9333
        static       = 9333
        host_network = "private"
      }

      port "grpc" {
        to           = 19333
        static       = 19333
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        command = "mkdir"
        args    = ["-p", "${local.strg}/master"]
      }
    }

    task "master" {
      driver = "docker"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      service {
        name     = "seaweedfs-master"
        port     = "http"
        provider = "nomad"
        tags     = ["private"]
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["http", "grpc"]

        args = [
          "master",
          "-mdir=/data",
          "-defaultReplication=200",
          "-volumeSizeLimitMB=1024",
          "-garbageThreshold=0.0001",
          "-ip=${NOMAD_IP_http}",
          "-ip.bind=0.0.0.0",
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
  }

  group "filer" {
    count = 3

    constraint {
      attribute = "${meta.storage}"
      value     = "large"
    }

    constraint {
      distinct_hosts = true
    }

    update {
      max_parallel = 1
      stagger      = "2m"
    }

    migrate {
      min_healthy_time = "2m"
    }

    network {
      port "http" {
        to           = 8888
        static       = 8888
        host_network = "private"
      }

      port "grpc" {
        to           = 18888
        static       = 18888
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        command = "mkdir"
        args    = ["-p", "${local.strg}/filer"]
      }
    }

    task "filer" {
      driver = "docker"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      resources {
        memory_max = 1024
      }

      service {
        name     = "seaweedfs-filer-${attr.unique.hostname}"
        port     = "http"
        provider = "nomad"
        tags     = ["private"]
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
        data        = <<-EOF
          {{- range nomadService "seaweedfs-master" -}}
          MASTER_ADDR={{ .Address }}:{{ .Port }}{{ end }}
        EOF
        destination = "env"
        env         = true
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["http", "grpc"]

        args = [
          "filer",
          "-master=${MASTER_ADDR}",
          "-s3=false",
          "-webdav=false",
          "-defaultReplicaPlacement=200",
          "-dataCenter=${attr.unique.hostname}",
          "-ip=${NOMAD_IP_http}",
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
  }

  group "volume" {
    count = 3

    constraint {
      attribute = "${meta.storage}"
      value     = "large"
    }

    constraint {
      distinct_hosts = true
    }

    update {
      max_parallel = 1
      stagger      = "2m"
    }

    migrate {
      min_healthy_time = "2m"
    }

    network {
      port "http" {
        to           = 8080
        static       = 8080
        host_network = "private"
      }

      port "grpc" {
        to           = 18080
        static       = 18080
        host_network = "private"
      }
    }

    task "preflight" {
      driver = "raw_exec"

      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      config {
        command = "mkdir"
        args    = ["-p", "${local.strg}/volume"]
      }
    }

    task "volume" {
      driver = "docker"

      kill_signal  = "SIGINT"
      kill_timeout = "90s"

      resources {
        memory_max = 4096
      }

      template {
        data        = <<-EOF
          {{- range nomadService "seaweedfs-master" -}}
          MASTER_ADDR={{ .Address }}:{{ .Port }}{{ end }}
        EOF
        destination = "env"
        env         = true
      }

      config {
        image = "chrislusf/seaweedfs:latest"
        ports = ["http", "grpc"]

        args = [
          "volume",
          "-mserver=${MASTER_ADDR}",
          "-max=100",
          "-dir=/data",
          "-dataCenter=${attr.unique.hostname}",
          "-ip=${NOMAD_IP_http}",
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
