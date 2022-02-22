# ory-sandbox
(wip) hydra &amp; kratos experiment

-----

**NOT WORKING**  
**This repo is a work in progress.  I've just started it.  As of right now, it does not work.**  

-----

## Helpful Information

### What is Koramo.Com?

The domain `koramo.com` is a garbage name of random letters I created years ago for testing purposes.  It's easy to pronouce and understand when teaching, so I keep it around for purposes like this.  Obviously, this domain will never work outside of my little testing environment.

### About the Public Ports

The purpose of this repo is to provide a "closer-to-real-world" example of the Ory Hydra setup without using ports everywhere.  I find their docs difficult to read because of their overuse of ports combined with the lack of real-world scenarios.  **In no way** am I advocating for anyone to open all of these ports to the public or to even advertise them by name in your zone files.  I am simply trying to add some clarity and labels to something that, at first glance, is too geek-like for anyone to easily wrap their head around.

### Public DNS Names

| FQDN | Purpose |
|----|----|
| consent.koramo.com	| Ory Login & Consent Example App |
| db.koramo.com	      | pgAdmin Web Interface |
| echo.koramo.com	    | Echo Server (also on `www.`) |
| hydra-a.koramo.com	  | Hydra Instance #1 Public Access  |
| hydra-a-admin.koramo.com	  | Hydra Instance #1 Public Access  |
| hydra-b.koramo.com	  | Hydra Instance #2 Public Access  |
| kratos.koramo.com	  | TBD |
| www.koramo.com      | Echo Server (also on `echo.`) |

### Ports Used in Ory Documentation

| PORT MAP | Purpose |
|----|----|
| 9000:4444 | Hydra A's Public Port |
| 9001:4445 | Hydra A's Admin Port |
| 9010:9010 | Hydra B's Public Port |
| 9020:3000 | Ory Login & Consent Example App |

### Ports from Extra Helper Apps

| PORT MAP | Purpose |
|----|----|
| 3001:80   | Echo Server |
| 3002:80   | pgAdmin Web Interface |

-----

## Host Setup

The following steps are used to configure our host environment.  NGINX is installed on the host computer to assist with routing FQDNs to services and web apps listening on local ports.

### NGINX Proxy Service

```bash
sudo usermod -aG docker ubuntu

sudo apt-get update
sudo apt-get install nginx
sudo service nginx start

sudo ufw allow 'nginx full'
```

**ADD NGINX CONFIGS AT THIS POINT**

An example [`nginx.conf`](./nginx/nginx.conf) file is provided [here](./nginx/nginx.conf).  Use this as a boilerplate if you are following along (be sure to change the domain name to your own).

After each modification to the NGINX config, verify the format of the config file is correct:

```bash
sudo nginx -t
sudo service nginx restart
```

### SSL Certificates

Once NGNIX is running, we will use Certbot to issue proper SSL certificates and configure them within NGINX.

```bash
sudo apt install certbot python3-certbot-nginx

sudo certbot --nginx --agree-tos \
--redirect --hsts --staple-ocsp \
--email fred.lackey@gmail.com \
-d consent.koramo.com,db.koramo.com,\
hydra-a.koramo.com,hydra-a-admin.koramo.com,\
hydra-b.koramo.com,\
www.koramo.com,koramo.com

```

-----

## Echo Server

The use of the `echo-server` project provides a means of testing basic NGINX functionality before proceeding with the setup of Hydra.  It is not needed in production.  

```bash
docker run -d \
  --name echo-server \
  -p 3001:80 \
  ealen/echo-server:0.5.1
```

At this point you should be able to access the Echo Server at any of the following URLs:

* `koramo.com` (no server name)
* `echo.koramo.com`
* `www.koramo.com`

-----

## Hydra Network

All name resolution between Docker containers happens within a virutal network.  

```bash
docker network create hydra
```
-----

## Database

Postgres is the chosen database within the Ory examples for Hydra.  For our convience, I have added pgAdmin to the mix.  For me, examining the data after each step helps cement the function in my mind and actuall _see_ what is happening.

First, the database...

```bash
docker run --network hydra \
  --name hydra-a-postgres \
  -e POSTGRES_USER=hydra \
  -e POSTGRES_PASSWORD=Pass1234 \
  -e POSTGRES_DB=hydra \
  -d postgres:9.6
```

... and now, pgAdmin...

```bash
docker run -p 3002:80 \
  --network hydra \
  --name hydra-pgadmin \
  -e 'PGADMIN_DEFAULT_EMAIL=fred.lackey@gmail.com' \
  -e 'PGADMIN_DEFAULT_PASSWORD=Pass1234!' \
  -d dpage/pgadmin4
```

Ory's documentation shows environment variables being used for common properties.  It's a bit annoying since the provided syntax only works in a Linux environment (sorry Windows nerds).

The following sytax builds the Hydra database schema by running required migrations from a command line interanl to a tempory container.

```bash
export DSN=postgres://hydra:Pass1234@hydra-a-postgres:5432/hydra?sslmode=disable

docker run -it --rm \
  --network hydra \
  oryd/hydra:v1.11.2 \
  migrate sql --yes $DSN
```
-----

## Hydra

The Ory documentation is horrible with their never-ending use of ports instead of FQDNs.  Below is a "before and after," with the names changed to something more human-readable.  I hope this helps.

> Taken from: https://www.ory.sh/docs/hydra/configure-deploy

### Original

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
### Modified

```bash
--network hydraguide connects this instance to the network and makes it possible to connect to the PostgreSQL database.
-p 9000:4444 exposes Ory Hydra's public API on https://hydra-a.koramo.com/.
-p 9001:4445 exposes Ory Hydra's administrative API on https://hydra-a-admin.koramo.com/.
-e SECRETS_SYSTEM=$SECRETS_SYSTEM sets the system secret environment variable (required).
-e DSN=$DSN sets the database url environment variable (required).
-e URLS_SELF_ISSUER=https://hydra-a.koramo.com/ this value must be set to the publicly available URL of Ory Hydra (required).
-e URLS_CONSENT=http://consent.koramo.com/consent this sets the URL of the consent provider (required). We will set up the service that handles requests at that URL in the next sections.
-e URLS_LOGIN=http://consent.koramo.com/login this sets the URL of the login provider (required). We will set up the service that handles requests at that URL in the next sections.
```
-----

```bash
export SECRETS_SYSTEM=Pass1234Pass1234

docker run -d \
  --name hydra-a \
  --network hydra \
  -p 9000:4444 \
  -p 9001:4445 \
  -e SECRETS_SYSTEM=$SECRETS_SYSTEM \
  -e DSN=$DSN \
  -e URLS_SELF_ISSUER=http://hydra-a.koramo.com/ \
  -e URLS_CONSENT=http://consent.koramo.com/consent \
  -e URLS_LOGIN=http://consent.koramo.com/login \
  oryd/hydra:v1.11.2 serve all --dangerous-force-http
```

-----

## Example #1 - Client Credentials Flow

As discusssed in the Ory docs section titled, "Performing the OAuth2 Client Credentials Flow":

> The easiest OAuth2 flow to try out is the Client Credentials Flow. To perform the flow we:
>  
>  a. create an OAuth 2.0 Client;  
>  b. perform the OAuth 2.0 Client Credentials Flow;  
>  c. Receive an OAuth 2.0 Access Token.  

From Oauth.NET:

> The Client Credentials grant type is used by clients to obtain an access token outside of the context of a user.
>  
> This is typically used by clients to access resources about themselves rather than to access a user's resources.
> 
> Reading:  
> https://oauth.net/2/grant-types/client-credentials/

### Step 1: Configure the client parameters for the flow

It is important to stress the Client Credentials Flow is a generally a *private* flow and does not use the client's browser.  

The following syntax uses a temporary / short-running container to invoke a single command.  This command Creates a new client, called "some-consumer" and tells Hydra to allow the "Client Credentials" grant type:

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://hydra-a:4445 \
    --id some-consumer \
    --secret some-secret \
    --grant-types client_credentials \
    --response-types token,code
```

### Step 2: Test Issuing the Token

The first step in the Client Credentials flow is to request an Access Token.  We use another short-lived Docker container to pass in the Client ID and Client Secret for this:

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  token client \
    --client-id some-consumer \
    --client-secret some-secret \
    --endpoint http://hydra-a:4444
```

> Note the that container is name is used for the endpoint.  This is because all of these calls are happening within the Docker network.  And, since they are all HTTP calls but _NOT_ on the default HTTP port, we must specify the port number the Hydra service is listening on.

The output of this command will be a single string of text (the token).  If you are following along, copy this into your clipboard buffer.  The one shown in the Ory docs is:

`ZcE0YWqnxemENLyJrjjlAHlFkdwaHB6TzkSi0c289HI.GQmXJsAYcw5de97S6mqOL0yB2UyFEf4DiXEM05vdfdY`

### Step 3: Validate the token

This token is not meant to be publicly read, like with a JWT.  Instead, one last short-lived Hydra container is used to test the validity of the token.

Pasting in the the token would cause their example:

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  token introspect \
    --endpoint http://hydra-a:4445 \
    >INSERT-TOKEN-HERE<
```
... to look like _this_...

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  token introspect \
    --endpoint http://hydra-a:4445 \
    ZcE0YWqnxemENLyJrjjlAHlFkdwaHB6TzkSi0c289HI.GQmXJsAYcw5de97S6mqOL0yB2UyFEf4DiXEM05vdfdY
```

Of course, don't use exactly what you see above.  This token won't exist in your system.  If you do, you'll see something like this:

```json
{
  "active": false,
  "aud": null
}
```

If done correctly, the output you should have is something like:

```json
{
  "active": true,
  "aud": [],
  "client_id": "some-consumer",
  "exp": 1645372014,
  "iat": 1645368414,
  "iss": "http://hydra-a.koramo.com/",
  "nbf": 1645368414,
  "sub": "some-consumer",
  "token_type": "Bearer",
  "token_use": "access_token"
}
```
-----

## Recap & Level Set

Until this point we've been testing a single instance of Hydra and just ensuring it works.  However, the ultimate goal of OAuth is to allow muliple systems to work together.  As we continue forward, do not mix this concept with the irony that Ory was kind enough to supply samples of a front-end.  Even as we implement a second instance of Hydra, remember that, during this exercise, we are mocking a scenario where multiple organizations just happen to be using Hydra.

## Caution - Hydra Instance #2

The Hydra docs make use of several tempoary containers which never remain running.  The user simply runs through their one-page "setup" guide running commands.  And, to me, it feels as if thier doc was written out of sequence or someone came back and injected a missing step in a few places.  For this reason, some of the steps I take in the next section show a slightly different flow so we configure everything and then proceed with the test.

-----

## Example #2: User Login & Consent Flow

The first example, above, was all command line and back end.  In my opinion, it's not what anything thinks of when first looking at OAuth.  More than likely they are thinking about how to use it for login purposes.  This is the next example the Ory docs show.

### Login & Consent Example App

It is important to remember the example we are using is one where your organization will own the entire authentication system.  Hydra itself only contains the underlying key logic and does not provide a user interface.  You stand it up and tuck it away behind the scenes.  Your "entrance" application is what is presented to the end user and will make a back-end call to your private instance of Hydra (on the Docker virtual network).  For that, Ory has provided an example app called, "Login & Consent".

```bash
docker run -d \
  --network hydra \
  --name hydra-consent \
  -p 9020:3000 \
  -e HYDRA_ADMIN_URL=http://hydra-a:4455 \
  -e NODE_TLS_REJECT_UNAUTHORIZED=0 \
  oryd/hydra-login-consent-node:v1.10.2
```

> Note the back end call using the `hydra-a` name only available in the Docker virtual network.  The port `4455` is used since it will make a HTTP call on a non-standard port.

> Also note that this repo shows this admin port being wide open to the public world at the name `hydra-a-admin`.  Don't ever do this.  I'm doing it here so we can play around with Hydra in our own playground and tack on some names to these port numbers.

In the first example, we configured an consumer with the name "Some Consumer".  Every client allowed to make an authorization call to the system should have its own identity.  So, before we proceed with this next flow, we need to setup an identity for that client, called "Another Consumer"

The Ory examples also show us using a second Hydra instance for this flow.  Keep your eye on the `callbacks` argument for the public URL of that instance.

So, let's spin up a temporary container and call to our currently running Hydra instance (called, "`hydra-a`") to create the new client identity:

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://hydra-a:4445 \
    --id another-consumer \
    --secret consumer-secret \
    -g authorization_code,refresh_token \
    -r token,code,id_token \
    --scope openid,offline \
    --callbacks http://hydra-b.koramo.com/callback
```

The tempoary container will spin up, perform the call to create the new client, and exit.  Just before it exists, it should send the following text to the console:

```bash
OAuth 2.0 Client ID: another-consumer
```

### Another Hydra Instance!!!

This confused the heck out of me when I first saw it.  It's proof the Ory docs are horrible.  I plan on writing a second follow-up to this using a real-world scenario with application names and the like.  However, for now, we are simply expanding on Ory's body of work to add a bit of clarity.

Long story short, Ory's docs have you standing up a *second* Hydra instance for the purpose of handling half of the User Login & Consent flow.  This is what the docs show:

![hydra-instance-2-block](./assets/img/hydra-instance-2-block.png)

Once we add in the translated FQDNS, this gives us the following:

**Important:**  
**If you are following along, and if you want to use their syntax the way they suggested, you may want to run this in a second terminal session since it does not return.**

```bash
docker run --rm -it \
  --network hydra \
  -p 9010:9010 \
  oryd/hydra:v1.11.2 \
  token user \
    --port 9010 \
    --auth-url http://hydra-a.koramo.com/oauth2/auth \
    --token-url http://hydra-a:4444/oauth2/token \
    --client-id another-consumer \
    --client-secret consumer-secret \
    --scope openid,offline \
    --redirect http://hydra-b.koramo.com/callback
```

Be careful at this step.  Regardlass of what you supply in this block, Hydra will still output the hard-coded garbage helper information it was designed to:

![hydra-instance-2-output](./assets/img/hydra-instance-2-output.png)

If the output was correct, it _would_ have been displayed like this:

```bash
Setting up home route on http://hydra-b.koramo.com/
Setting up callback listener on http://hydra-b.koramo.com/callback
Press ctrl + c on Linux / Windows or cmd + c on OSX to end the process.
If your browser does not open automatically, navigate to:

        http://hydra-b.koramo.com/
```

For me, I chose to run the second instance in daemon mode and give it a name...

```bash
docker run --rm -it -d \
  --network hydra \
  --name hydra-b \
  -p 9010:9010 \
  oryd/hydra:v1.11.2 \
  token user \
    --port 9010 \
    --auth-url http://hydra-a.koramo.com/oauth2/auth \
    --token-url http://hydra-a:4444/oauth2/token \
    --client-id another-consumer \
    --client-secret consumer-secret \
    --scope openid,offline \
    --redirect http://hydra-b.koramo.com/callback
```

### Add the Consumer App








### Consumer App

the following appear to be using the localhost only because the are being used at the command line
in prod this would probably be performed by some type of administrative api call

use the command line to setup a local route so the next command line will be able to function  

```bash
docker run --rm -it \
  --network hydra \
  oryd/hydra:v1.11.2 \
  clients create \
    --endpoint http://hydra-a:4445 \
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