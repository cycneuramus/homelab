# see https://docs.searxng.org/admin/engines/settings.html#use-default-settings
use_default_settings: true
server:
    # can be disabled for a private instance
    limiter: false
    image_proxy: true
    #enc!
    secret_key: ENC[AES256_GCM,data:u3ILcRHKY6pUS5S8rVP2S7EPaoqeOhNSPX0sY4w=,iv:SNVbtd/+a+trYFxqlI3icsgeNFTvf5h79bo/ncLsQNQ=,tag:H+bR/SakMZGykkO77o9exw==,type:str]
valkey:
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
    age:
        - recipient: age14nu42yf645xewsdgq03rwytpxw4pf6elmlwz9q3yundv32h8l3xqvq7hvn
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB0VWhnVC9KTUlZcEJvL1hC
            ZXd3SzdLVmRVYkFCb2svRENnVGhoYS9GSjFrCjFYS3VuVWRFZXhxTGdGOGQvSXhR
            YWk2anQzeHJqVWVhQWpxdjZ5RS9EMTgKLS0tIGg3WCt2ZmNTVDdyTzZxdVlmVFdj
            TFEyNmV4b2ZQL1ZSNnNJaWVVOU1kSE0K53LG84HwsbB4sqh1b2xiwbfHtL+lQEud
            opb7efA5rIOOg3B/r5IooSCuMC/h07kyfmxmXXMPDPlm59qrcsVTeQ==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2026-03-12T09:44:54Z"
    mac: ENC[AES256_GCM,data:OPR/tmnP6xyn6y/n4dePoxGmm8ObWpiHT0Lo2KrMaEdCYFR26iM2gdJ3jNHp1M3aQM4N2aVDJ1ZWCn5Mw/66BR/uULHh4s0TkDLYXewfVpdX+YSzPbiocEpNtBFS8DyS1E0TPc/5T3XlNuqZi733q+xSlSg5rnYruzHQ/2XxxiI=,iv:QO1R3cKJKpHc2Tk0luMXn+J0xzkw/L9nsolELU1cDxc=,tag:RTi5YFft1/Vt1XsraHpUAg==,type:str]
    encrypted_comment_regex: enc!
    version: 3.10.2
