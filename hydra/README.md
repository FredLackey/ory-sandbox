
# [ory-sandbox](../) / Hydra

## Files

Two primary files exist to help you stand up Hydra: the NGINX config file and the syntax file.  Both of these are very opinionated and what I used to standup Hydra in my sandbox environment.  They are meant to simply add clarity.  I strongly advise _not_ using them in production:

| FILE | DESCRIPTION |
|----|----|
| [`files/nginx.conf`](./files/nginx.conf) | NGINX configuration file showing name mappings |
| [`files/syntax.md`](./files/syntax.md) | Example syntax using host names instead of the loopback and ports |
| [`files/syntax.sh`](./files/syntax.sh) | Same syntax file but in a text format, just in case |
| [`COMPARISON.md`](COMPARISON.md) | Visual side-by-side comparison of my version versus Ory's |

## Public Ports

The purpose of this repo is to provide a "closer-to-real-world" example of the Ory Hydra setup without using ports everywhere.  I find their docs difficult to read because of their overuse of ports combined with the lack of real-world scenarios.  **In no way** am I advocating for anyone to open all of these ports to the public or to even advertise them by name in your zone files.  I am simply trying to add some clarity and labels to something that, at first glance, is too geek-like for anyone to easily wrap their head around.

## Public DNS Names

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

## Ports Used in Ory Documentation

| PORT MAP | Purpose |
|----|----|
| 9000:4444 | Hydra A's Public Port |
| 9001:4445 | Hydra A's Admin Port |
| 9010:9010 | Hydra B's Public Port |
| 9020:3000 | Ory Login & Consent Example App |

## Ports from Extra Helper Apps

| PORT MAP | Purpose |
|----|----|
| 3001:80   | Echo Server |
| 3002:80   | pgAdmin Web Interface |

