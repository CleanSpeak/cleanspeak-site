In order to get ssl for your documentation images you will have to create a self signed certificate


# Create a cert
Use the following script to generate:

```shell script
# Generate encrypted key
openssl genrsa -aes192 -passout pass:x -out server.pass.key 2048

# Save unencrypted key
openssl rsa -passin pass:x -in server.pass.key -out server.key

# Remove encrypted key
rm server.pass.key

# Create the certificate request
openssl req -new -out server.csr -key server.key -config server.conf

# Self sign
openssl x509 -req -days 365 -in server.csr -signkey server.key -sha256 -out server.crt -extensions req_ext -extfile server.conf
```

Note the `-extensions req_ext` and `-extfile server.conf`; these files are required to get a proper wildcard certificate.

Now you need to use that cert in your http server.

## Nginx

Change the cert directories to suit your cert location

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name local.cleanspeak.io;

    ssl_certificate /Users/tyler/dev/inversoft/cleanspeak/cleanspeak-site/cert/server.crt;
    ssl_certificate_key /Users/tyler/dev/inversoft/cleanspeak/cleanspeak-site/cert/server.key;

    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;

    ssl_prefer_server_ciphers on;

    proxy_redirect off;
    proxy_set_header X-Real_IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Port 443;

    location / {
        proxy_pass http://localhost:8011;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name local.cleanspeak.io;
    rewrite ^(.*) https://$server_name$1 permanent;
}
```

## Apache
TODO

# Install cert

In order to use a certificate you will have to get your system to trust it.

## MacOS

1. Open KeyChain
1. Drag the `server.crt` into your keychain
1. (Approve the security if it asks)
1. Right click on your cert and say get info
1. Open the Trust section
1. Change the `When using this certificate` to `Always Trust`
1. Close
1. (Approve the security if it asks)

You can now use `*.cleanspeak.io` and `*.cleanspeak.com` without any security warnings in chrome and safari on MacOS

## Windows
TODO

## Linux
TODO
