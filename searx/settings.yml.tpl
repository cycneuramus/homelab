# see https://docs.searxng.org/admin/engines/settings.html#use-default-settings
use_default_settings: true
server:
    # can be disabled for a private instance
    limiter: false
    image_proxy: true
    #enc!
    secret_key: ENC[AES256_GCM,data:7vVWQL7HJN9vhN2DUBXtk45o0hZXHywR3Sg4oZQ=,iv:wM8XHXGmLD9n++mt+71qrEmG90f6kbakQwInR1XPQy0=,tag:WPPaVEk9lJ83k6OfJ8+ZBw==,type:str]
redis:
    url: redis://{{ env "NOMAD_ADDR_redis" }}/0
general:
    enable_metrics: false
search:
    default_lang: en
ui:
    static_use_hash: true
    default_locale: sv
outgoing:
    max_request_timeout: 5
categories_as_tabs:
    general: null
    images: null
    videos: null
    files: null
    map: null
    news: null
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
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
        - recipient: age14nu42yf645xewsdgq03rwytpxw4pf6elmlwz9q3yundv32h8l3xqvq7hvn
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAyUVBSZDJHUHZKcm8xazAr
            Mndzcld2ZGVmbi9PbDh6Z2ZWSVdFQ3ltN2hZClRSNzdlZnlyTis0NTY5a1BLUTdL
            U0NoMmtLdUd0bDBneDZBTXQ3NW9Uam8KLS0tIGtKMndVbE9pb1dhNDR1Z2p1VUh2
            ZnNZTEh3c0hJZ1Z0cy9VcENBWDFLSlEKaslgYUB/iz494n5rF99NjFsA6lVvUtKM
            sdqhJRph7ADc9NnRZAqv717zj0jh/779RULOLlwcgfLkJNsKp9jmAQ==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2025-01-21T11:41:46Z"
    mac: ENC[AES256_GCM,data:1ooOM8r/uMuy4KyL2YZNIUphtRyIs/7YBSfyeg+mRMACI2oVzPf+V4AZfOilIuulfpshTgIgs2VkJqa0G/kdy7n/A+BBfJzq+lJzecqBiltDmSjM7qsCney3kX+Rg0OyRkdl1TvND83AUT/Lj7Q/zlN0vDWCFC4i440QRw+NLUE=,iv:9jvVMmdObr45fQFk7GkagD2n1fA9nhfAtyFQ/QB7NmE=,tag:e8+n/W9POrIC0m3nAbD4gg==,type:str]
    pgp: []
    encrypted_comment_regex: enc!
    version: 3.9.3
