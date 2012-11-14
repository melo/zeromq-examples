# Complex Request/Reply chain #

Multiple clients, multiple service workers, multiple layers of load-
balancers.

# How-to start the demo #

You can start all the elements in any order but I prefer to start the
load balancers first.


## Load-balancers ##

The first level load-balancer. Binds on port 8123 and 8124. Clients
connect to 8123. The id for this load-balancer is `lb-1.0`:

    ./queue.pl --id=lb-1.0 --in=:8123 -out=:8124

The second level of load-balancers will connect to 8124 of the first,
and accept service workers on ports 8125 and 8126.

    ./queue.pl --id=lb-2.1 --in=8124 -out=:8125
    ./queue.pl --id=lb-2.2 --in=8124 -out=:8126

## Service workers ##

You can start how many service workers you want, just make sure you
distribute them over the two second level load balancers.

    ./service.pl --port=8125 --connect
    ./service.pl --port=8125 --connect
    ./service.pl --port=8125 --connect
    ./service.pl --port=8126 --connect
    ./service.pl --port=8126 --connect
    ./service.pl --port=8126 --connect

## Client ##

You can start how many clients you want. If you use the --id option,
make sure each client has a different one.

    ./client.pl --connect --id=cln


# What to watch out for #

You should see how the request are load-balanced over the two second
level load balancers and their respective services in round-robin.

Also, if you look at the first and second level load balancer traffic,
the routing parts should be visible, with the IDs of each process.
