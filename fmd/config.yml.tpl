DatabaseDir: /var/lib/fmd-server/db
UnixSocketPath: ""
UnixSocketChmod: 432
PortSecure: 8443
PortInsecure: 8080
UserIdLength: 5
MaxSavedLoc: 10
MaxSavedPic: 10
#enc!
RegistrationToken: ENC[AES256_GCM,data:5r0J9QNvgCWYaxyUPdz3xpVHEQqRyhT8TrKwUit5bg==,iv:CrcZGYA4Bq7Y2c60q9wLzmT/kXu+kgnljFOT5E61P+s=,tag:0CAwsGoi0OvHUQMh9kPZbQ==,type:str]
ServerCrt: ""
ServerKey: ""
sops:
    age:
        - recipient: age14nu42yf645xewsdgq03rwytpxw4pf6elmlwz9q3yundv32h8l3xqvq7hvn
          enc: |
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBDb1ZWb2hxN01nTmJOY2pG
            bVFkZWVnWjhtMVZNUm15T09CZDB2K0Z3TTNZCllhMXRyT3RKekZaRlFwcy9SOEpj
            UE1tbVFERnpnN2RPaUwxNWx5MW5udFUKLS0tIGNQTUR6RDVDWkUvQVBMdHVYckk0
            dWd3cW41VUdjbGlMWllFVml4YjJ1TlkKFQB5/iQIhrxQhtD1A/DibasH9HwIBT6h
            CDmsgti3L8+gm3Wp3Posht7i7b6rt5i3kHwzwwXU3eGq8+0UqTJ11g==
            -----END AGE ENCRYPTED FILE-----
    lastmodified: "2025-10-09T07:29:32Z"
    mac: ENC[AES256_GCM,data:Jz+Gio0hrIZoEjmMe5jfk5Nh5WtOSqqzueJgXM5OWf5ZTe+GnHISMsA5CQLh2I8Y9x28wa7OwfKmivZbUloDjYcT1QAtka3dSwLgOtrs0LA3allIglUnkA+HjMX92oSjxuAjf0CRogza1kY9l1mTJEePOSJ1UZn30lKGl4hkyNg=,iv:neAc6uyrV+6gEW26r6PODqkLiXgQLmOgM3X9hpkOpKY=,tag:iaEjM28zl9uKylhad55+sA==,type:str]
    encrypted_comment_regex: enc!
    version: 3.10.2
