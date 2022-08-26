# Idea

This package proivdes a way to startd up a configured regtest environment for testing.

There are a couple of levels of working with it, and I do both: handy bash scripts, and just `docker exec`ing random crap.

Generally, this is a docker-compose.yml and a couple of resources that help bootstrap nodes.

### Start it up

```
$ docker-compose up &
```

This will generate a ton of scroll as it brings up a bitcoin node and a bunch of lightning nodes.

Next you need to do some bitcoin wallet initialization.  You can do that by running the script:

```
$ ./init_bitcoind.sh
```

This takes a few seconds since it generates the first hundred blocks so that you'll have some spendable bitcoin to work with.

The terminal window that you're running docker-compose-up in is going to be barfing a lot of output, and be generally unusable probably, so one more thing thing I like to do is start my block generator script in this same window:

```
$ ./generate_blocks.sh
```

That will start mining blocks every (30 seconds).  Of course you can just open that shell script and change the rate of block generation if you want easily.

Now you can inetract with any of the nodes pretty easily from the command line

```
$ docker exec lnd lncli --network=regtest newaddress p2wkh
{
    "address": "bcrt1qppnl8j2g83k2uhxgrad99uz0ewandkm4fl5crs"
}
```

Or you can use some of the handy scripts.

For sure when you're getting started you should do:

```
./fund_nodes.sh
./peer_graph.sh 
./channel_graph.sh
```

Fund nodes will spray bitcoin around, peer_graph will network the nodes together, and then channel_graph will actually open channels between them.

### Shut it down

You can uses `docker-compose down` to tear everything down.  `docker stop`/start/kick whatever container you want, etc. 

I provided a `./reset_everthyng.sh` script that will start from some pristine state in theory.

Note that the volumes directory contains subdirectories that get mounted into each node.  So you can mess with the node system from outside, edit config files, etc.

The `resources` directory has files that the cluster may need for bootstrapping (initial configs, etc.)

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
