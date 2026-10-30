{
  "@type": "PostgreSql",
  "timeout": 15000,
  "useTls": false,
  "allowInvalidCerts": false,
  "poolMaxConnections": 10,
  "poolRecyclingMethod": "fast",
  "readReplicas": {},
  "host": {{ env "attr.unique.network.ip-address" | toJSON }},
  "port": 15432,
  "database": "stalwart_v1",
  "authUsername": "stalwart_v1",
  "authSecret": {
    "@type": "EnvironmentVariable",
    "variableName": "STALWART_DB_PASSWORD"
  },
  "options": null
}
