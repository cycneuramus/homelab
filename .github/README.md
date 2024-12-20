## Overview

This repository contains the skeleton files for a homelab of self-hosted services orchestrated by [Nomad](https://nomadproject.io). The infrastructure is similar to the one provisioned by [ansible-hybrid-cloud](https://github.com/cycneuramus/ansible-hybrid-cloud/tree/homelab-only).

### Highlights

+ Containerized workloads using rootless [Podman](https://developer.hashicorp.com/nomad/plugins/drivers/podman) as the task driver
+ [Caddy](https://caddyserver.com) as [L4](https://github.com/mholt/caddy-l4) and L7 reverse proxy with [full automation](https://github.com/cycneuramus/homelab/blob/master/caddy/Caddyfile.tpl) by means of [Nomad service discovery](https://developer.hashicorp.com/nomad/docs/networking/service-discovery) templating
+ [HAProxy](https://www.haproxy.org/) as [internal load balancer](https://github.com/cycneuramus/homelab/blob/master/haproxy/cfg-haproxy.cfg) for infrastructure services
+ Highly available [Garage S3](https://garagehq.deuxfleurs.fr) deployment with [JuiceFS](https://juicefs.com) mounts connected to a [KeyDB](https://docs.keydb.dev) cluster over UNIX sockets for distributed storage
+ Highly available [PostgreSQL](https://www.postgresql.org) database cluster using [Patroni](https://github.com/zalando/patroni)
+ All services aside from the reverse proxy are closed to the outside world, communicating only over a private Wireguard mesh network

### NOTE

The Nomad job definitions will contain references to various sensitive environment and configuration files which are not included in this repository.
