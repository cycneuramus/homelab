. {
    forward . 192.168.1.1
}

service.nomad. {
    errors
    debug
    health
    log
    nomad service.nomad {
        address http://{{ env "attr.unique.network.ip-address" }}:4646
        ttl 30
    }
    cache 30
}

