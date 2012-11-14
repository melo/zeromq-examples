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
my $cln = zmq_socket($ctx, ZMQ_REQ);

zmq_setsockopt($cln, ZMQ_IDENTITY, $id) if $id;

if ($connect) {
  zmq_connect($cln, "tcp://127.0.0.1:$port");
}
elsif ($bind) {
  zmq_bind($cln, "tcp://127.0.0.1:$port");
}

print "Ready... Type a phrase and hit enter.\n";

while (<>) {
  chomp;
  zmq_sendmsg($cln, $_);
  print "sent: '$_'\n";
  my $msg = zmq_recvmsg($cln);
  print "recv: '" . zmq_msg_data($msg) . "'\n\n";
}


sub usage {
  print "ERROR: @_\n\n" if @_;

  print <<EOU;
Usage: client.pl [--port=N] [--connect] [--bind] [--help]

    --help      print this help message
    --port=N    use TCP port N on the localhost (default to 8123)
    --connect   connect to the port
    --bind      bind to the port

EOU
  exit(1);
}
