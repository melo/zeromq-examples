#!/usr/bin/env perl

use strict;
use warnings;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';
use Getopt::Long;

die "Not working for now, LibZMQ3 does not support zmq_proxy yet\n";

my ($smart, $help);
my $port = 8124;
GetOptions('smart' => \$smart, 'help' => \$help, 'port' => \$port) or usage();
usage() if $help;

my ($in_port, $out_port) = ($port, $port+1);

my $ctx = zmq_init();
my ($in_sock_type, $out_sock_type) = (ZMQ_SUB, ZMQ_PUB);
($in_sock_type, $out_sock_type) = (ZMQ_XSUB, ZMQ_XPUB) if $smart;
my $sub = zmq_socket($ctx, $in_sock_type);
my $pub = zmq_socket($ctx, $out_sock_type);

zmq_bind($sub, "tcp://127.0.0.1:$in_port");
zmq_bind($pub, "tcp://127.0.0.1:$out_port");

print "Starting proxy... Connect PUBs to $in_port, SUBs to $out_port\n";
zmq_proxy($sub, $pub);

sub usage {
  print "ERROR: @_\n\n" if @_;

  print <<EOU;
Usage: proxy.pl [--smart] [--port=N] [--help]

    --help      print this help message
    --port=N    use TCP port N on the localhost (default to 8124)
    --smart     use XPUB/XSUB instead of PUB/SUB

The port is the base port number. Publishers should connect to it,
and subscribers should connect to port + 1.

EOU
  exit(1);
}
