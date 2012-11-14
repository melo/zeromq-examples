#!/usr/bin/env perl

use strict;
use warnings;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';
use Getopt::Long;

my ($smart, $proxy, $help);
my $port = 8123;
GetOptions('smart' => \$smart, 'help' => \$help, 'port' => \$port, 'proxy' => \$proxy) or usage();
usage() if $help;

my $ctx       = zmq_init();
my $sock_type = ZMQ_PUB;
$sock_type = ZMQ_XPUB if $smart;
my $pub = zmq_socket($ctx, $sock_type);
if ($proxy) {
  zmq_connect($pub, "tcp://127.0.0.1:$proxy");
}
else {
  zmq_bind($pub, "tcp://127.0.0.1:$port");
}

my $count = 0;
while (1) {
  zmq_send($pub, $count, length($count), ZMQ_MSG_MORE);
  my $m = "msg $count";
  zmq_send($pub, $m);
  print "pub: $count => $m\n";
  sleep(1);
  $count++;
  $count = 0 if $count > 7;
}


sub usage {
  print <<EOU;
Usage: producer.pl [--smart] [--port=N] [--help]

    --help      print this help message
    --port=N    use TCP port N on the localhost (default to 8123)
    --smart     use XPUB/XSUB instead of PUB/SUB

EOU
  exit(1);
}
