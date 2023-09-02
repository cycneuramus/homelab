#!/bin/sh

{{- range nomadService "immich-server" }}
immich upload \
	--key <api-key> \
	--server http://{{ .Address }}:{{ .Port }} \
	--recursive /extracted \
	--yes

immich upload \
	--key <api-key> \
	--server http://{{ .Address }}:{{ .Port }} \
	--recursive /user-1 \
	--yes

immich upload \
	--key <api-key> \
	--server http://{{ .Address }}:{{ .Port }} \
	--recursive /user-2 \
	--yes
{{- end -}}
