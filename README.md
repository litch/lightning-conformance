# Idea

This package provides a way to startd up a configured regtest environment for testing.

There are a couple of levels of working with it, and I do both: handy bash scripts, and just `docker exec`ing random stuff.

Generally, this is a docker-compose.yml and a couple of resources that help bootstrap nodes, and then a growing application that lets you see and manipulate the graph/traffic.

### Configuration

Docker should be running in rootless mode to avoid lots of weird permissions/collisions.

https://docs.docker.com/engine/security/rootless/

### Start it up

```
bin/reset
```

### Thunderhub!

A thunderhub instance is available at <hostname>:4200

The password for all the nodes is `password`

### Structure

- `volumes/` contains subdirectories that get mounted into each node.  So you can mess with the node system from outside, edit config files, etc.

- `resources/` directory has files that the cluster may need for bootstrapping (initial configs, etc.)
- `operator/` is where the python/graphql app live that let you drive it

- Lots of random scripts - basically everything works by `docker exec`ing to any of the nodes and running `lncli --network=regtest` or `lightning-cli --network=regtest`

## Dependencies

## Mac
brew install coreutils jq

## Linux

jq


# Basic Commands

Docker exec'ing random stuff

- `docker exec cln-c1 lightning-cli --network=regtest newaddr bech32`

Handy shell scripts!

- `./fund_nodes.sh`


## Thanks Nigiri

I used a lot of the guts of Nigiri to do this, but threw away most of their stuff.  I also started learning Rust with Paul while I was writing a little CLI that probably doesn't work anymore.

I'm also working on a project in this `visualize` directory to make visualization easier.  It's an absolute mess right now.

In any case, enjoy!
