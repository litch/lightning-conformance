# Operator Server

This is an application that interacts with the lightning nodes that it was told about by the conformance testing library.

In "using this in a docker container mode" all the networknig should just work.  If you are doing development of it, you want to copy the `config/nodes-example.ini` file to `config/nodes.ini` and change any ports as necessary.