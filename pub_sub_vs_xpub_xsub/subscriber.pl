#!/usr/bin/env perl

use strict;
use warnings;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';
use Getopt::Long;

my ($smart, $help);
my $port = 8123;
GetOptions('smart' => \$smart, 'help' => \$help, 'port' => \$port) or usage();
usage() if $help;

my ($topic) = @ARGV;
usage("Missing topic") unless defined $topic;

my $ctx = zmq_init();
my $sock_type = ZMQ_SUB;
$sock_type = ZMQ_XSUB if $smart;
print "Scket type SUB ",ZMQ_SUB," XSUB ",ZMQ_XSUB," - using ", $sock_type,"\n";
my $sub = zmq_socket($ctx, $sock_type);

zmq_setsockopt($sub, ZMQ_SUBSCRIBE, $topic) unless $smart;
zmq_connect($sub, "tcp://127.0.0.1:$port");
zmq_send($sub, "\1$topic");

my $count = 0;
while (1) {
  my $buffer;
  zmq_recv($sub, $buffer, 1024);
  print "[$$] recv: $buffer\n";
}


sub usage {
  print "ERROR: @_\n\n" if @_;

  print <<EOU;
Usage: subscriber.pl [--smart] [--port=N] [--help] <topic>

    --help      print this help message
    --port=N    use TCP port N on the localhost (default to 8123)
    --smart     use XPUB/XSUB instead of PUB/SUB

You need to include a topic, a number from 0 to 7.

EOU
  exit(1);
}
