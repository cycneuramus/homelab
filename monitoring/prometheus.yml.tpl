global:
  scrape_interval: 15s

scrape_configs:
  - job_name: reverse-proxy
    static_configs:
    - targets:
      {{ range nomadServices -}}
      {{- range nomadService .Name -}}
      {{- if contains "reverse-proxy" .Name -}}
      - "{{ .Address }}:{{ .Port }}"
      {{ end -}}
      {{- end -}}
      {{- end }}
  - job_name: l4-proxy
    static_configs:
    - targets:
      {{ range nomadServices -}}
      {{- range nomadService .Name -}}
      {{- if contains "l4-proxy" .Name -}}
      - "{{ .Address }}:{{ .Port }}"
      {{ end -}}
      {{- end -}}
      {{- end }}
