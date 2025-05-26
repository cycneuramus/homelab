DatabaseDir: /var/lib/fmd-server/db
WebDir: /usr/share/fmd-server/web
UnixSocketPath: ""
UnixSocketChmod: 432
PortSecure: 8443
PortInsecure: 8080
UserIdLength: 5
MaxSavedLoc: 10
MaxSavedPic: 10
#enc!
RegistrationToken: ENC[AES256_GCM,data:U0fzS+Hubm+Lv1q7/+LhgauQBsSfFGELMrIWbo9EuA==,iv:YJcwXYK2bNOROwlyNYDtbVIDkoixPialKnVqfbcKhis=,tag:s1zTVTCSxd48EgWI9jxO3w==,type:str]
ServerCrt: ""
ServerKey: ""
sops:
    age:
        - recipient: age14nu42yf645xewsdgq03rwytpxw4pf6elmlwz9q3yundv32h8l3xqvq7hvn
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAvR1RyTU9RMEJkYU93bWF6
            NFB0eGxyYk9UeUJZNC85V2Q2SnZOZkZ2T2lJCkhXRmF6OUF3M0wyTjZHaVZBWUJI
            MFJaUm5zNTBOMGJoRUhLMW9xSjlrSzQKLS0tIC9menNpVFl6YmxOMUJ2RFV5SUUw
            RVZja1RuTmVhRHJyL0ZHRHBLTFAzNjAKkThsG4mTKoLikDx7siketO12nqR2mGbD
            KjqmfDR0g/Etty1L/5qzP6uAOr8qGgjsyzRKzCNr9e/KC3ppUZRE+Q==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2025-05-26T08:27:44Z"
    mac: ENC[AES256_GCM,data:TN/MImqK/MkFXYX3eAS45ykQ+wYtVxEgcS30nTwJDU5/j3mJYCblvREKcd3UhAtJw/wIKdv63I/xFe9UNJSFS1JFOTEErY1yvuqG1rIQId/tSHWdIeHqTVGO+qnpXaeawpj41r95FRri2ocRGdSvYoqjtSmbK3UDMVaxfkcuZfc=,iv:2PBxe84rmD8WiLF9r7h0g7VGkBp7+DmkBM6k1cbHFqY=,tag:45zmI+/zBCu8ODOqszl/iQ==,type:str]
    encrypted_comment_regex: enc!
    version: 3.10.1
