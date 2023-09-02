{
	"storage": {
		"module": "redis",
		{{ range nomadService "caddy-redis" -}}
		"address": "{{ .Address }}:{{ .Port }}{{ end }}",
		"db": 1
	},
	"logging": {
		"logs": {
			"default": {
				"encoder": {
					"format": "console",
					"time_format": "wall"
				}
			}
		}
	},
	"admin": {
		"listen": ":2019"
	},
	"apps": {
		"http": {
			"servers": {
				"": {
					"metrics": {}
				}
			}
		},
		"layer4": {
			"servers": {
				"adguard-home": {
					"listen": [
						":853"
					],
					"routes": [
						{
							"match": [
								{
									"tls": {
										"sni": [
											"dns.example.com"
										]
									}
								}
							],
							"handle": [
								{
									"handler": "proxy",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "adguard" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				},
				"mail-1": {
					"listen": [
						":25"
					],
					"routes": [
						{
							"handle": [
								{
									"handler": "proxy",
									"proxy_protocol": "v1",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "mailserver-25" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				},
				"mail-2": {
					"listen": [
						":465"
					],
					"routes": [
						{
							"match": [
								{
									"tls": {
										"sni": [
											"mail.example.com"
										]
									}
								}
							],
							"handle": [
								{
									"handler": "proxy",
									"proxy_protocol": "v1",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "mailserver-465" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				},
				"mail-3": {
					"listen": [
						":993"
					],
					"routes": [
						{
							"match": [
								{
									"tls": {
										"sni": [
											"mail.example.com"
										]
									}
								}
							],
							"handle": [
								{
									"handler": "proxy",
									"proxy_protocol": "v2",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "mailserver-10993" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				},
				"bedrock": {
					"listen": [
						"udp/0.0.0.0:37663"
					],
					"routes": [
						{
							"handle": [
								{
									"handler": "proxy",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "minecraft-bedrock" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				},
				"minecraft": {
					"listen": [
						"tcp/0.0.0.0:37663"
					],
					"routes": [
						{
							"handle": [
								{
									"handler": "proxy",
									"upstreams": [
										{
											"dial": [
											{{- $upstream := nomadService "minecraft-java" -}}
											{{- if $upstream -}}
											{{- range $upstream }}
												"{{ .Address }}:{{ .Port }}"{{ end }}
											{{- else }}
												"localhost:1111"
											{{- end }}
											]
										}
									]
								}
							]
						}
					]
				}
			}
		}
	}
}
