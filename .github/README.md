## Overview

This repository contains job definitions for a homelab of self-hosted services orchestrated by [Nomad](https://nomadproject.io), leveraging containerized workloads with a focus on high availability, automation, and security. The infrastructure runs on bare-metal [Debian Stable](https://wiki.debian.org/DebianStable) and is provisioned by [ansible-hybrid-cloud](https://github.com/cycneuramus/ansible-hybrid-cloud/tree/homelab-only).

---

### Architecture

- **Orchestration**:
    - [Nomad](https://nomadproject.io) for workload management
    - Rootless [Podman](https://podman.io) as the [task driver](https://developer.hashicorp.com/nomad/docs/drivers)
    
- **Networking**: 
    - Private [Wireguard](wireguard.com) mesh for all inter-service communication
  - [Caddy](https://caddyserver.com) as [L4](https://github.com/mholt/caddy-l4) and L7 reverse proxy
  - [HAProxy](https://www.haproxy.org/) for [internal load balancing](https://github.com/cycneuramus/homelab/blob/master/haproxy/cfg-haproxy.cfg) of infrastructure services

- **Storage**:
  - [Garage S3](https://garagehq.deuxfleurs.fr) cluster for durable object storage
  - [JuiceFS](https://juicefs.com): POSIX-compliant distributed mounts with:
    - Garage S3 as storage backend
    - Multi-tier caching (memory -> disk -> S3)
  - [KeyDB](https://docs.keydb.dev) cluster for JuiceFS metadata storage over UNIX sockets

- **Database**:
    - [PostgreSQL](https://www.postgresql.org) cluster using [Patroni](https://github.com/zalando/patroni)
    - Regular database dumps to encrypted offsite storage
  
---

### Key Features

- **Security**:
  - Container isolation with rootless execution where possible
  - Zero public exposure - all services communicate via Wireguard
  - [SOPS](https://github.com/getsops/sops)-encrypted secrets with [Git integration](https://github.com/cycneuramus/git-sops)

- **Automation**:
    - [Self-updating](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl) reverse proxy configurations using [Nomad service discovery](https://developer.hashicorp.com/nomad/docs/networking/service-discovery)
    - Rolling or [Blue-Green](https://developer.hashicorp.com/nomad/tutorials/job-updates/job-blue-green-and-canary-deployments) update deployments for critical services
    -  Self-hosted [Renovate bot](https://docs.renovatebot.com/) creating PRs for [new container version tags](https://github.com/cycneuramus/homelab/blob/master/.github/renovate.json)
    - Regular pruning and cleanups via [Nomad periodic jobs](https://developer.hashicorp.com/nomad/docs/job-specification/periodic) 
    - Service monitoring and alerting with [Gatus](https://github.com/TwiN/gatus)

---

> [!NOTE]
> Some configuration files and/or environment variables may be excluded from this repository
