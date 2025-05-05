{
    skip_install_trust

    cert_issuer acme {
        email {$EMAIL}
        dns cloudflare {$CLOUDFLARE_TOKEN}
        resolvers 1.1.1.1
        propagation_delay 10s
        propagation_timeout -1
    }

    log {
        # level debug
        format console {
            time_format wall
        }
    }

    storage redis {
        {{ range nomadService "caddy-redis" -}}
        address "{{ .Address }}:{{ .Port }}" {{ end }}
        db 1
    }

    filesystem s3-fs s3 {
        bucket cld
        region us-east-1
        endpoint http://{{ env "attr.unique.network.ip-address" }}:13900
        use_path_style
    }

    servers {
        trusted_proxies static private_ranges
    }

    admin :2019
    metrics

    layer4 {
        :25 {
            route {
                proxy {
                    proxy_protocol v2
                    {{- $upstream := nomadService "smtp" -}}
                    {{- if $upstream -}}
                    {{- range $upstream }}
                    upstream {{ .Address }}:{{ .Port }}{{ end }}
                    {{- else }}
                    upstream localhost:1111
                    {{- end }}
                }
            }
        }

        :465 {
            @secure tls sni mail.{$DOMAIN}
            route @secure {
                # tls
                proxy {
                    proxy_protocol v2
                    {{- $upstream := nomadService "smtps" -}}
                    {{- if $upstream -}}
                    {{- range $upstream }}
                    upstream {{ .Address }}:{{ .Port }}{{ end }}
                    {{- else }}
                    upstream localhost:1111
                    {{- end }}
                }
            }
        }

        :993 {
            @secure tls sni mail.{$DOMAIN}
            route @secure {
                # tls
                proxy {
                    proxy_protocol v2
                    {{- $upstream := nomadService "imaps" -}}
                    {{- if $upstream -}}
                    {{- range $upstream }}
                    upstream {{ .Address }}:{{ .Port }}{{ end }}
                    {{- else }}
                    upstream localhost:1111
                    {{- end }}
                }
            }
        }
    }
}

(access-control) {
    # @geofilter {
    #   not maxmind_geolocation {
    #       db_path "/etc/caddy/GeoLite2-Country.mmdb"
    #       deny_countries {$DENIED_COUNTRIES}
    #   }
    #   not remote_ip {$IP_SELF}
    # }

    @ai-crawlers {
        header_regexp User-Agent "(?i)(Bytespider|CCBot|Diffbot|FacebookBot|Google-Extended|GPTBot|omgili|anthropic-ai|Claude-Web|ClaudeBot|cohere-ai)"
    }
    handle @ai-crawlers {
        abort
    }

    @local-only {
        expression `{access} == "local"`
        not remote_ip {$IP_SELF}
    }
    handle @local-only {
        respond @local-only "Forbidden" 403 {
            close
        }
    }

    @unknown expression `{upstream} == "unknown"`
    handle @unknown {
        respond @unknown "Not found" 404 {
            close
        }
    }
}


(basicauth) {
    @auth{args[0]} {
        expression `{labels.2} == "{args[0]}"`
        not remote_ip {$IP_SELF}
    }

    basic_auth @auth{args[0]} {
        {args[1]} {args[2]}
    }
}

(logging) {
    log {
        # format formatted
        output file /var/log/access.log {
            roll_keep 1
            roll_keep_for 7d
        }
    }
}

(loadbalance) {
    @{args[0]} expression `{labels.2} == "{args[0]}"`
    route @{args[0]} {
        reverse_proxy {args[1:]} {
            # lb_policy first
            lb_policy client_ip_hash
            lb_try_duration 10s
            fail_duration 30s
        }
    }
}

(security) {
    @security expression `{labels.2} != "nextcloud"`
    route @security {
        header {
            Permissions-Policy interest-cohort=()
            Strict-Transport-Security "max-age=31536000;"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            X-Robots-Tag "none"
            X-Permitted-Cross-Domain-Policies "none"
            X-XSS-Protection "1; mode=block"
            Referrer-Policy "no-referrer-when-downgrade"
        }
    }
}

(dynamic_srv) {
    reverse_proxy {
        dynamic srv {args[0]} {
            refresh 15s     # CoreDNS TTL / 2
            resolvers {{ env "attr.unique.network.ip-address" }}:1053
        }

        transport http {
            resolvers {{ env "attr.unique.network.ip-address" }}:1053
        }

        lb_policy client_ip_hash
        lb_try_duration 10s
        fail_duration 10s
    }

}

(honeypot-quirks) {
    @honeypot expression `{labels.2} == "honeypot"`
    handle @honeypot {
        reverse_proxy {{ env "attr.unique.network.ip-address" }}:9000
    }
}

(libreddit-quirks) {
    @libreddit expression `{labels.2} == "libreddit" || {labels.2} == "r"`
    route @libreddit {
        rewrite /bc {$LIBREDDIT_BC}
        rewrite /it {$LIBREDDIT_IT}
    }
}

(matrix-quirks) {
    @matrix expression `{labels.2} == "matrix"`
    route @matrix {
        @well-known-server path /.well-known/matrix/server
        handle @well-known-server {
            respond `{"m.server":"matrix.{$DOMAIN}:443"}`
        }

        @well-known-client path /.well-known/matrix/client
        handle @well-known-client {
            respond `{"m.server":{"base_url":"https://matrix.{$DOMAIN}"},"m.homeserver":{"base_url":"https://matrix.{$DOMAIN}","org.matrix.msc3575.proxy":{"url":"https://matrix.{$DOMAIN}"}}`
        }
    }
}

(nextcloud-quirks) {
    @nextcloud expression `{labels.2} == "nextcloud"`
    route @nextcloud {
        header Strict-Transport-Security max-age=31536000;

        redir /.well-known/carddav /remote.php/dav 301
        redir /.well-known/caldav /remote.php/dav 301

        handle /push/* {
            uri strip_prefix /push
            import dynamic_srv nextcloud-push.default.service.nomad 
        }
    }
}

(nomad-quirks) {
    @nomad expression `{labels.2} == "nomad"`
    handle @nomad {
        reverse_proxy 192.168.1.200:4646
    }
}

(s3-quirks) {
    @s3 expression `{labels.2} == "s3"`
    handle @s3 {
        reverse_proxy {{ env "attr.unique.network.ip-address" }}:13900
    }
}

(stfn-quirks) {
    @stfn expression `{labels.2} == "stfn"`
    handle @stfn {
        handle /rom* {
            file_server {
                fs s3-fs
                root stfn
            }
        }
    }
}

*.{$DOMAIN} {
    map {labels.2} {upstream} {access} {
        {{ $skip := parseJSON `["private"]` -}}
        {{- range nomadServices -}}
        {{- if containsNone $skip .Tags -}}
        {{- $tag := "local" -}}
        {{- if (.Tags | contains "public") -}}
        {{- $tag = "public" -}}
        {{- end -}}
        {{ printf "%s %s.default.service.nomad %s" (.Name) (.Name) $tag }}
        {{ end -}}
        {{- end -}}

        nomad quirk local
        s3 quirk public
        stfn quirk public

        default unknown local
    }

    encode zstd gzip

    import logging
    import access-control
    import security

    # import basicauth arcade {$TM_USER} {$TM_PASSWORD}
    import basicauth hannes {$WP_USER} {$WP_PASSWORD}
    import basicauth tm {$TM_USER} {$TM_PASSWORD}

    import honeypot-quirks
    import libreddit-quirks
    import matrix-quirks
    import nextcloud-quirks
    import nomad-quirks
    import s3-quirks
    import stfn-quirks

    import dynamic_srv {upstream}
}

*.{$ALT_DOMAIN} {
    map {labels.2} {upstream} {access} {
        f transfer.default.service.nomad public
        r libreddit.default.service.nomad public

        default unknown local
    }

    encode zstd gzip

    import logging
    import access-control
    import security

    import libreddit-quirks

    import dynamic_srv {upstream}
}

{$DOMAIN}, {$ALT_DOMAIN} {
    # Enforce correct matching and access-control for www-requests
    @www host www.{$DOMAIN} www.{$ALT_DOMAIN}
    redir @www https://{host[1]}{uri} permanent

    map {path} {access} {
        / local

        default public
    }

    encode zstd gzip

    import logging
    import access-control
    import security

    import dynamic_srv {upstream}
}
