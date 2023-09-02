{
	email {$EMAIL}
	skip_install_trust

	acme_dns cloudflare {$CLOUDFLARE_TOKEN}

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

	servers {
		metrics
	}

	admin :2019
}

(access-control) {
	@local-only {
		expression `{access} == "local"`
		not remote_ip {$IP_SELF}
	}

	respond @local-only "Forbidden" 403

	@unknown expression `{upstream} == "unknown"`
	redir @unknown https://www.youtube.com/watch?v=dQw4w9WgXcQ
}


(basicauth) {
	@auth{args[0]} {
		expression `{labels.2} == "{args[0]}" || {labels.3} == "{args[0]}"`
		not remote_ip {$IP_SELF}
	}

	basicauth @auth{args[0]} {
		{args[1]} {args[2]}
	}
}

(logging) {
	log {
		format formatted
		output file /var/log/access.log {
			roll_keep 1
			roll_keep_for 7d
		}
	}
}

(reverse_proxy-failover) {
	reverse_proxy {args[0]} {args[1]} {
		transport http {
			dial_timeout 3s
			response_header_timeout 5s
		}
		lb_policy first
		lb_try_duration 10s
		fail_duration 30s
	}
}

(security) {
	@security expression `{labels.2} != "nextcloud" && {labels.3} != "nextcloud"`
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

(nextcloud-quirks) {
	@nextcloud expression `{labels.2} == "nextcloud"`
	route @nextcloud {
		header Strict-Transport-Security max-age=31536000;

		redir /.well-known/carddav /remote.php/dav 301
		redir /.well-known/caldav /remote.php/dav 301

		handle /push/* {
			uri strip_prefix /push
			{{ range nomadService "nextcloud-push" -}}
			reverse_proxy {{ .Address }}:{{ .Port }}{{ end }} {
				trusted_proxies private_ranges
			}
		}
	}
}

*.{$DOMAIN} {
	map {labels.2} {upstream} {access} {
	{{ range nomadServices -}}
	{{- range nomadService .Name -}}
	{{- if .Tags | contains "private" | not -}}
		{{ .Name | toLower }} {{ .Address }}:{{ .Port }} {{- if .Tags | contains "public" }} public {{- end }}
	{{ end -}}
	{{- end -}}
	{{- end -}}

		nomad 10.10.10.10:4646
		syncthing 10.10.10.11:8384

		default unknown local
	}

	encode zstd gzip

	import logging
	import access-control
	import security

	import basicauth arcade {$TM_USER} {$TM_PASSWORD}
	import basicauth tm {$TM_USER} {$TM_PASSWORD}

	import libreddit-quirks
	import nextcloud-quirks

	reverse_proxy {upstream}
}

*.{$ALT_DOMAIN} {
	map {labels.2} {upstream} {access} {
		f {{ range nomadService "transfer" }}{{ .Address }}:{{ .Port }}{{ end }}
		r {{ range nomadService "libreddit" }}{{ .Address }}:{{ .Port }}{{ end }}

		default unknown public
	}

	encode zstd gzip

	import logging
	import access-control
	import security

	reverse_proxy {upstream}
}

{$ALT_DOMAIN} {
	map {path} {access} {
		/ local

		default public
	}

	encode zstd gzip

	import logging
	import access-control
	import security

	reverse_proxy {{ range nomadService "kutt" }}{{ .Address }}:{{ .Port }}{{ end }}
}
