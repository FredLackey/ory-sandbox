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
  --name ory-hydra-example--hydra \
  --network hydraguide \
  -p 9000:4444 \
  -p 9001:4445 \
  -e SECRETS_SYSTEM=$SECRETS_SYSTEM \
  -e DSN=$DSN \
  -e URLS_SELF_ISSUER=http://127.0.0.1:9000/ \
  -e URLS_CONSENT=http://127.0.0.1:9020/consent \
  -e URLS_LOGIN=http://127.0.0.1:9020/login \
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

docker run --rm -it -d \
  --network hydraguide \
  --name ory-hydra-example--hydra2 \
  -p 9010:9010 \
  oryd/hydra:v1.11.2 \
  token user \
    --port 9010 \
    --auth-url http://127.0.0.1:9000/oauth2/auth \
    --token-url http://ory-hydra-example--hydra:4444/oauth2/token \
    --client-id another-consumer \
    --client-secret consumer-secret \
    --scope openid,offline \
    --redirect http://127.0.0.1:9010/callback

http://127.0.0.1:9010