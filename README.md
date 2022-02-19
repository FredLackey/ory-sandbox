# ory-sandbox
(wip) hydra &amp; kratos experiment

| FQDN | Purpose |
|----|----|
| db.koramo.com	      | pgAdmin |
| hydra.koramo.com	  | Hydra (public access)   |
| kratos.koramo.com	  | |
| www.koramo.com      | |
| members.koramo.com  | consent & login   |

**PORTS USED IN ORY DOCS**

| PORT MAP | Purpose |
|----|----|
| 9000:4444 | Hydra Public Port   |
| 9001:4445 | Hydra Admin Port (back end)   |
| 9010:9010 | Consumer App   |
| 9020:3000 | Consent 

**EXTRA SERVICE PORTS**

| PORT MAP | Purpose |
|----|----|
| 3001:80   | Echo service   |
| 3002:80   | pgAdmin   |

-----

## Host Setup

```bash
sudo usermod -aG docker ubuntu

sudo apt-get update
sudo apt-get install nginx
sudo service nginx start

sudo ufw allow 'nginx full'

**ADD NGINX CONFIGS AT THIS POINT**

!verify the format of the config file is correct

```bash
sudo nginx -t
sudo service nginx restart

sudo apt install certbot python3-certbot-nginx

sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email fred.lackey@gmail.com -d auth.koramo.com,consent.koramo.com,consumer.koramo.com,db.koramo.com,echo.koramo.com,hydra.koramo.com,kratos.koramo.com,members.koramo.com,resource.koramo.com,userapp.koramo.com,www.koramo.com,koramo.com
```

-----

## Testing Only

echo-server used for testing to ensure everything is running properly with nginx without hydra (not needed in prod)

```bash
docker run -d \
  --name echo-server \
  -p 3001:80 \
  ealen/echo-server:0.5.1
```
-----

## Hydra Network

```bash
docker network create hydra
```
-----

## Database

```bash
docker run --network hydra \
  --name hydra-postgres \
  -e POSTGRES_USER=hydra \
  -e POSTGRES_PASSWORD=Pass1234 \
  -e POSTGRES_DB=hydra \
  -d postgres:9.6
```
pagdmin here for convenience during testing (not needed in prod)

```bash
docker run -p 3002:80 \
  --network hydra \
  --name hydra-pgadmin \
  -e 'PGADMIN_DEFAULT_EMAIL=fred.lackey@gmail.com' \
  -e 'PGADMIN_DEFAULT_PASSWORD=Pass1234!' \
  -d dpage/pgadmin4

export DSN=postgres://hydra:Pass1234@hydra-postgres:5432/hydra?sslmode=disable
```
build database schema by running required hydra migrations

```bash
docker run -it --rm \
  --network hydra \
  oryd/hydra:v1.11.2 \
  migrate sql --yes $DSN
```
-----

## Hydra

from: https://www.ory.sh/docs/hydra/configure-deploy

```bash
--network hydraguide connects this instance to the network and makes it possible to connect to the PostgreSQL database.
-p 9000:4444 exposes Ory Hydra's public API on https://localhost:9000/.
-p 9001:4445 exposes Ory Hydra's administrative API on https://localhost:9001/.
-e SECRETS_SYSTEM=$SECRETS_SYSTEM sets the system secret environment variable (required).
-e DSN=$DSN sets the database url environment variable (required).
-e URLS_SELF_ISSUER=https://localhost:9000/ this value must be set to the publicly available URL of Ory Hydra (required).
-e URLS_CONSENT=http://localhost:9020/consent this sets the URL of the consent provider (required). We will set up the service that handles requests at that URL in the next sections.
-e URLS_LOGIN=http://localhost:9020/login this sets the URL of the login provider (required). We will set up the service that handles requests at that URL in the next sections.
```
modified for fqdn

```bash
--network hydraguide connects this instance to the network and makes it possible to connect to the PostgreSQL database.
-p 9000:4444 exposes Ory Hydra's public API on https://hydra.koramo.com/.
-p 9001:4445 exposes Ory Hydra's administrative API on https://localhost:9001/.
-e SECRETS_SYSTEM=$SECRETS_SYSTEM sets the system secret environment variable (required).
-e DSN=$DSN sets the database url environment variable (required).
-e URLS_SELF_ISSUER=https://hydra.koramo.com/ this value must be set to the publicly available URL of Ory Hydra (required).
-e URLS_CONSENT=http://consent.koramo.com/consent this sets the URL of the consent provider (required). We will set up the service that handles requests at that URL in the next sections.
-e URLS_LOGIN=http://consent.koramo.com/login this sets the URL of the login provider (required). We will set up the service that handles requests at that URL in the next sections.
```
-----

```bash
export SECRETS_SYSTEM=Pass1234Pass1234

docker run -d \
  --name hydra \
  --network hydra \
  -p 9000:4444 \
  -p 9001:4445 \
  -e SECRETS_SYSTEM=$SECRETS_SYSTEM \
  -e DSN=$DSN \
  -e URLS_SELF_ISSUER=http://hydra.koramo.com/ \
  -e URLS_CONSENT=http://consent.koramo.com/consent \
  -e URLS_LOGIN=http://consent.koramo.com/login \
  oryd/hydra:v1.11.2 serve all --dangerous-force-http
```
setup the consent app with the back end path to the hydra service
specify the port since it's using HTTP at a non-standard port
since the call to hydra is running within the hydra network, the name of the contianer is used

```bash
docker run -d \
  --network hydra \
  --name hydra-consent \
  -p 9020:3000 \
  -e HYDRA_ADMIN_URL=http://hydra:4455 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  oryd/hydra-login-consent-node:v1.10.2
```
-----

## Consumer App

the following appear to be using the localhost only because the are being used at the command line
in prod this would probably be performed by some type of administrative api call

use the command line to setup a local route so the next command line will be able to function  

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://hydra:4445 \
    --id another-consumer \
    --secret consumer-secret \
    -g authorization_code,refresh_token \
    -r token,code,id_token \
    --scope openid,offline \
    --callbacks http://consumer.karamo.com/callback

docker run --rm -it \
  --network hydra \
  -p 9010:9010 \
  oryd/hydra:v1.11.2 \
  token user \
    --port 9010 \
    --auth-url http://127.0.0.1:9000/oauth2/auth \
    --token-url http://ory-hydra-example--hydra:4444/oauth2/token \
    --client-id another-consumer \
    --client-secret consumer-secret \
    --scope openid,offline \
    --redirect http://consumer.karamo.com/callback
```
instructions originally read as follows

```bash
Setting up home route on http://127.0.0.1:9010/
Setting up callback listener on http://127.0.0.1:4445/callback
Press ctrl + c on Linux / Windows or cmd + c on OSX to end the process.
If your browser does not open automatically, navigate to:

        http://127.0.0.1:9010/
```
but now read ...

```bash
Setting up home route on http://resource.koramo.com/
Setting up callback listener on http://127.0.0.1:4445/callback
Press ctrl + c on Linux / Windows or cmd + c on OSX to end the process.
If your browser does not open automatically, navigate to:

        http://resource.koramo.com/
```