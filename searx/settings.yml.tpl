use_default_settings: true
server:
  secret_key: "" # change this!
  limiter: false
  image_proxy: true
redis:
  url: redis://{{ env "NOMAD_ADDR_redis" }}/0
general:
  enable_metrics: false
search:
  default_lang: "en"
ui:
  static_use_hash: true
  default_locale: "sv"
outgoing:
  max_request_timeout: 5.0
categories_as_tabs:
  general:
  images:
  videos:
  files:
  map:
  news:
engines:
  - name: bing
    disabled: false
  - name: brave
    disabled: false
  - name: duckduckgo
    disabled: false
  - name: google-en
    engine: google
    language: en
    use_mobile_ui: true
    shortcut: genglish
  - name: google-swe
    engine: google
    language: sv
    use_mobile_ui: true
    shortcut: gswedish
  - name: qwant
    disabled: true
