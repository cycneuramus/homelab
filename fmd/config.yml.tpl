UnixSocketPath: ""
UnixSocketChmod: 432
PortSecure: 8443
PortInsecure: 8080
UserIdLength: 5
MaxSavedLoc: 10
MaxSavedPic: 10
#enc!
RegistrationToken: ENC[AES256_GCM,data:m5RwhuoNe2WxrmXZZ9jrzVkWD2o6gKXjx7ItzC/fIA==,iv:soy5h4ojVJW0mHtwH1r3gOBaVpzc2yAQvf1xIEgNrZ4=,tag:y8s36fVTuxacudtZPRWcMg==,type:str]
ServerCrt: ""
ServerKey: ""
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
        - recipient: age14nu42yf645xewsdgq03rwytpxw4pf6elmlwz9q3yundv32h8l3xqvq7hvn
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBjUDRLWEpzT2cvM0Z5Vmxy
            dG1vTkVkdjJ6d1JRQkQ2OCtsL1VUS0dKMWdjCnJUN3UzRUV0TkYxWkhQRmtYSDBJ
            bHZqQnZHRWY0S3JtWkVCdDIvZlB4a3MKLS0tIEZFUW9BY2c5OHg1K0dLdjJWOFUy
            UkRFTTd0U0VYSk55bVJTRUlYTFZ6TnMKA1Hf/yNni3qcRbkzfYER+1za4PAwD5SB
            V/oR37jCeCpWJNQJNDBo4+g+M+FCMiUvWAFjK+RG/C5fLO1lfgbHfQ==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2025-01-21T11:17:59Z"
    mac: ENC[AES256_GCM,data:eky3lxRM0DptLYBb5UIx6YzYHJiYpTnwIWxvKQx1xycEHxKuZ7vluzM8aI3hAiv2Rg1df6EAFvcNLAv6rEIJiRbQ/o5fERnMbHZqiWsZQeBWmOIUSEPB6GyT5pz1yNGcnrzmQ6L4UFUtJLrfbEB3CHkHqgyFrB687THoOOiBU7Q=,iv:+zMPlBzFaknq5WPbnB0wG9FVXwJyPc3Zl8EHTA9yHEg=,tag:HUVNEA5a07QNGE6Ia+ygOA==,type:str]
    pgp: []
    encrypted_comment_regex: enc!
    version: 3.9.3
