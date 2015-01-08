# Distributed System

Use https://erlangcentral.org/wiki/index.php?title=A_Framework_for_Clustering_Generic_Server_Instances for passive replication

## TODO

Use better serialization (probably MessagePack.
Use logger.
Refactor some parts of the code.

## Compiling

$make

## Run
	
Server *2 or more

* $./startServer.sh name (*2 name different)
* net_adm:ping(node). (to connect node, Do in 1 node)
* serverErlang:start_link(). (Do in nodes)

Client

$./startClient.sh namePlayer
