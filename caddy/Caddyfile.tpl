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

    # Ensure old connections are closed e.g. on Nomad redeploys
    grace_period 10s

    admin :2019
    metrics

    layer4 {
        :22 {
            route {
                proxy {
                    proxy_protocol v2
                    {{- $upstream := nomadService "honeypot-ssh" -}}
                    {{- if $upstream -}}
                    {{- range $upstream }}
                    upstream {{ .Address }}:{{ .Port }}{{ end }}
                    {{- else }}
                    upstream localhost:1111
                    {{- end }}
                }
            }
        }

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

        # header_regexp User-Agent "(?i)(AI2Bot|Ai2Bot\-Dolma|aiHitBot|Amazonbot|Andibot|anthropic\-ai|Applebot|Applebot\-Extended|Awario|bedrockbot|Brightbot\ 1\.0|Bytespider|CCBot|ChatGPT\-User|Claude\-SearchBot|Claude\-User|Claude\-Web|ClaudeBot|cohere\-ai|cohere\-training\-data\-crawler|Cotoyogi|Crawlspace|Datenbank\ Crawler|Devin|Diffbot|DuckAssistBot|Echobot\ Bot|EchoboxBot|FacebookBot|facebookexternalhit|Factset_spyderbot|FirecrawlAgent|FriendlyCrawler|Gemini\-Deep\-Research|Google\-CloudVertexBot|Google\-Extended|GoogleOther|GoogleOther\-Image|GoogleOther\-Video|GPTBot|iaskspider/2\.0|ICC\-Crawler|ImagesiftBot|img2dataset|ISSCyberRiskCrawler|Kangaroo\ Bot|meta\-externalagent|Meta\-ExternalAgent|meta\-externalfetcher|Meta\-ExternalFetcher|MistralAI\-User|MistralAI\-User/1\.0|MyCentralAIScraperBot|netEstate\ Imprint\ Crawler|NovaAct|OAI\-SearchBot|omgili|omgilibot|Operator|PanguBot|Panscient|panscient\.com|Perplexity\-User|PerplexityBot|PetalBot|PhindBot|Poseidon\ Research\ Crawler|QualifiedBot|QuillBot|quillbot\.com|SBIntuitionsBot|Scrapy|SemrushBot\-OCOB|SemrushBot\-SWA|Sidetrade\ indexer\ bot|SummalyBot|Thinkbot|TikTokSpider|Timpibot|VelenPublicWebCrawler|WARDBot|Webzio\-Extended|wpbot|YandexAdditional|YandexAdditionalBot|YouBot)"
    
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

(auth) {
    @auth{args[0]} {
        expression `{labels.2} == "{args[0]}"`
        not remote_ip {$IP_SELF}
    }

    route @auth{args[0]} {
        {{- $upstream := nomadService "auth" -}}
        {{- if $upstream -}}
        {{- range $upstream }}
        forward_auth {{ .Address }}:{{ .Port }}{{ end }} {
        {{- else }}
        forward_auth localhost:1111 { {{- end }}
            uri /api/auth/caddy
        }
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
            lb_retries 2
            lb_try_duration 10s
            fail_duration 30s
        }
    }
}

(security) {
    @security expression `!({labels.2}.matches("^(nextcloud|opencloud|wopi)$"))`
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

(libreddit-quirks) {
    @libreddit expression `{labels.2} == "libreddit" || {labels.2} == "r"`
    route @libreddit {
        rewrite /bc {$LIBREDDIT_BC}
        rewrite /it {$LIBREDDIT_IT}

        @block path / /r/all/*
        handle @block {
            respond @block "Forbidden" 403 {
                close
            }
        }
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
    redir @nextcloud https://opencloud.{$DOMAIN}{uri}
    # route @nextcloud {
    #     header Strict-Transport-Security max-age=31536000;

    #     redir /.well-known/carddav /remote.php/dav 301
    #     redir /.well-known/caldav /remote.php/dav 301

    #     handle /push/* {
    #         uri strip_prefix /push
    #         import dynamic_srv nextcloud-push.default.service.nomad 
    #     }

    #     @collabora path /hosting/discovery* /hosting/capabilities* /cool/* /browser/* /loleaflet/* /cool/adminws*
    #     handle @collabora {
    #         import dynamic_srv collabora.default.service.nomad
    #     }
    # }
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

(pizza-quirks) {
    @pizza expression `{labels.2} == "pizza"`
    handle @pizza {
        file_server {
            fs s3-fs
            root pizza
        }
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

:8080 {
    import dynamic_srv honeypot-http.default.service.nomad
}

:8443 {
    import dynamic_srv honeypot-https.default.service.nomad
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
        s3 quirk local
        pizza quirk public
        stfn quirk public

        default unknown local
    }

    encode zstd gzip

    import logging
    import access-control
    import security

    import auth hannes
    import auth notes
    import auth tm

    import libreddit-quirks
    import matrix-quirks
    import nextcloud-quirks
    import nomad-quirks
    import s3-quirks
    import pizza-quirks
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

    import dynamic_srv kutt.default.service.nomad
}
