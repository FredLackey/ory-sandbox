#!/bin/bash

sudo usermod -aG docker ubuntu

sudo apt-get update
sudo apt-get install nginx
sudo service nginx start

sudo ufw allow 'nginx full'

# ADD NGINX CONFIGS AT THIS POINT

sudo nginx -t
sudo service nginx restart

sudo apt install certbot python3-certbot-nginx

sudo certbot --nginx --agree-tos \
  --redirect --hsts --staple-ocsp \
  --email fred.lackey@gmail.com \
  -d consent.koramo.com,db.koramo.com,\
  hydra-a.koramo.com,hydra-a-admin.koramo.com,\
  hydra-b.koramo.com,\
  www.koramo.com,koramo.com

docker run -d \
  --name echo-server \
  -p 3001:80 \
  ealen/echo-server:0.5.1

# BEGIN ACTUAL HYDRA WORKFLOW

docker network create hydraguide

docker run --network hydraguide \
  --name ory-hydra-example--postgres \
  -e POSTGRES_USER=hydra \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=hydra \
  -d postgres:9.6

export SECRETS_SYSTEM=Pass1234Pass1234

export DSN=postgres://hydra:secret@ory-hydra-example--postgres:5432/hydra?sslmode=disable

docker run -it --rm \
  --network hydraguide \
  oryd/hydra:v1.11.2 \
  migrate sql --yes $DSN

docker run -d \
  --name ory-hydra-example--consent \
  -p 9020:3000 \
  --network hydraguide \
  -e HYDRA_ADMIN_URL=http://ory-hydra-example--hydra:4445 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  oryd/hydra-login-consent-node:v1.10.2

docker run -d \
  --name ory-hydra-example--hydra \
  --network hydraguide \
  -p 9000:4444 \
  -p 9001:4445 \
  -e SECRETS_SYSTEM=$SECRETS_SYSTEM \
  -e DSN=$DSN \
  -e URLS_SELF_ISSUER=https://hydra-a.koramo.com/ \
  -e URLS_CONSENT=https://consent.koramo.com/consent \
  -e URLS_LOGIN=https://consent.koramo.com/login \
  oryd/hydra:v1.11.2 serve all --dangerous-force-http

docker run --rm -it \
  --network hydraguide \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://ory-hydra-example--hydra:4445 \
    --id some-consumer \
    --secret some-secret \
    --grant-types client_credentials \
    --response-types token,code

docker run --rm -it \
  --network hydraguide \
  oryd/hydra:v1.11.2 \
  token client \
    --client-id some-consumer \
    --client-secret some-secret \
    --endpoint http://ory-hydra-example--hydra:4444

docker run --rm -it \
  --network hydraguide \
  oryd/hydra:v1.11.2 \
  token introspect \
    --endpoint http://ory-hydra-example--hydra:4445 \
    >INSERT-TOKEN-HERE<

docker run --rm -it \
  --network hydraguide \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://ory-hydra-example--hydra:4445 \
    --id another-consumer \
    --secret consumer-secret \
    -g authorization_code,refresh_token \
    -r token,code,id_token \
    --scope openid,offline \
    --callbacks https://hydra-b.koramo.com/callback

docker run --rm -it -d \
  --network hydraguide \
  --name ory-hydra-example--hydra2 \
  -p 9010:9010 \
  oryd/hydra:v1.11.2 \
  token user \
    --port 9010 \
    --auth-url https://hydra-a.koramo.com/oauth2/auth \
    --token-url http://ory-hydra-example--hydra:4444/oauth2/token \
    --client-id another-consumer \
    --client-secret consumer-secret \
    --scope openid,offline \
    --redirect https://hydra-b.koramo.com/callback

# Final starting point for test:
# https://hydra-b.koramo.com
