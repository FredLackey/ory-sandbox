# Run your own OAuth2 Server

## Clarification of Ory Hydra Document

The Ory document, titled "Run your own OAuth2 Server" is rather confusing.  This repo provides improved scripts for applying the concepts in that document to a more realistic environment using machine names and NGINX.  This document offers a visual comparison of the differences between the files contained here and the original Ory document [located here](https://www.ory.sh/run-oauth2-server-open-source-api-security/)

## NGINX

For this solution to work, we need a mechanism for hiding the Ory ports behind a fully-qualified machine name.  The first section of my version tackles the installation of NGINX as well as installing a simple Echo Server.  This Echo Server is not needed in production.  It's added here so you have something to test against should Ory or NGINX not work properly.

![comparison-001](./assets/img/comparison-001.png)

## Network & Database

No real difference here.  The only thing I added was some static test values for the two environment variables Ory suggested you use.

![comparison-002](./assets/img/comparison-002.png)

asdf
![comparison-003](./assets/img/comparison-003.png)

asdf
![comparison-004](./assets/img/comparison-004.png)

asdf
![comparison-005](./assets/img/comparison-005.png)

asdf
![comparison-006](./assets/img/comparison-006.png)

asdf
![comparison-007](./assets/img/comparison-007.png)

asdf
