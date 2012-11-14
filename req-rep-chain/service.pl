#!/usr/bin/env perl

use strict;
use warnings;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';
use Getopt::Long;

my ($help, $bind, $connect, $id);
my $port = 8123;
GetOptions('help' => \$help, 'port=i' => \$port, 'bind' => \$bind, 'connect' => \$connect, "id=s" => \$id) or usage();
usage() if $help;
usage("only one of --connect and --bind is supported") if $connect and $bind;
usage("need one of --connect and --bind") unless $connect or $bind;

my $ctx = zmq_init();
my $srv = zmq_socket($ctx, ZMQ_REP);

zmq_setsockopt($srv, ZMQ_IDENTITY, $id) if $id;

if ($connect) {
  zmq_connect($srv, "tcp://127.0.0.1:$port");
  print "connect to tcp://127.0.0.1:$port\n";
}
elsif ($bind) {
  zmq_bind($srv, "tcp://127.0.0.1:$port");
}

while (1) {
  print "waiting for request...\n";
  my $msg = zmq_recvmsg($srv);

  $msg = zmq_msg_data($msg);
  print "\tin: '$msg'\n";

  $msg = uc($msg);

  zmq_send($srv, $msg, length($msg));
  print "\tout: '$msg'\n\n";
}


sub usage {
  print "ERROR: @_\n\n" if @_;

  print <<EOU;
Usage: service.pl [--port=N] [--connect] [--bind] [--help]

    --help      print this help message
    --port=N    use TCP port N on the localhost (default to 8123)
    --connect   connect to the port
    --bind      bind to the port

EOU
  exit(1);
}
