# ory-sandbox
Ory Hydra &amp; Kratos Experiment

-----

**NOT COMPLETE**  
**This repo is a work in progress.  I've just started it.  As of right now, Hydra works.  Once I figure out Kratos I'll add that as well.**  

-----

## Background  

Long story short, the Ory documentation sucks.  This repo was started to help me wrap my head around their product and, in the process, hopefully help others who may just be starting out with Hyra and Kratos.  I am not an expert in either of these technologies.

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

