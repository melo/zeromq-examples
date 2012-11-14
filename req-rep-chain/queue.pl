#!/usr/bin/env perl

use strict;
use warnings;
use ZMQ::LibZMQ3;
use ZMQ::Constants ':all';
use Getopt::Long;

my ($help, $id, $in_port, $out_port);
GetOptions('help' => \$help, "id=s" => \$id, 'in=s' => \$in_port, 'out=s', \$out_port) or usage();
usage("Missing required --in")  unless $in_port;
usage("Missing required --out") unless $out_port;
usage() if $help;

my $ctx = zmq_init();
my $in  = zmq_socket($ctx, ZMQ_ROUTER);
my $out = zmq_socket($ctx, ZMQ_DEALER);

zmq_setsockopt($out, ZMQ_IDENTITY, $id) if $id;

print localtime() . " - Gateway device starting, REQs to $in_port, REPs to $out_port\n";

for ([$in, $in_port], [$out, $out_port]) {
  my ($sock, $port) = @$_;
  if ($port =~ /^:\d+/) { print "\t... bind $port\n"; zmq_bind($sock, "tcp://127.0.0.1$port") }
  else                  { print "\t... connect $port\n"; zmq_connect($sock, "tcp://127.0.0.1:$port") }
}
print "\n";

my @queue;
while (1) {
  my $cnt = zmq_poll(
    [ { socket   => $in,
        events   => ZMQ_POLLIN,
        callback => sub { forward_message('in => out', $in, $out) }
      },
      { socket   => $out,
        events   => ZMQ_POLLIN,
        callback => sub { forward_message('out => in', $out, $in) }
      },
    ],
    10_000
  );
  while (my $job = shift @queue) {
    my ($sock, @parts) = @$job;
    while (defined(my $part = shift @parts)) {
      my @flags;
      push @flags, ZMQ_SNDMORE if @parts;
      my $rv = zmq_send($sock, $part, length($part), @flags);
    }
    print "\n";
  }
}

sub forward_message {
  my ($dir, $in, $out) = @_;
  my @out_msg = ($out);

  print "Message $dir:\n";

  my $part_no = 0;
  my $more    = 1;
  while ($more) {
    my $msg = zmq_recvmsg($in);
    $more = zmq_getsockopt($in, ZMQ_RCVMORE);

    $part_no++;
    print "\t$part_no $more: (" . zmq_msg_size($msg) . ") '" . zmq_msg_data($msg) . "'\n";

    push @out_msg, zmq_msg_data($msg);
  }
  print "\n";

  push @queue, \@out_msg;
}


sub usage {
  print "ERROR: @_\n\n" if @_;

  print <<EOU;
Usage: queue.pl --in=<port> --out=<port> [-id=s] [--help]

    --help      print this help message
    --id        set the identification for the outgoing socket
    --in        port to use the incoming (ROUTER) port
    --out       port to use the outgoing (DEALER) port

The <port> can be a number or a :number. The first option will use
connect, the second will use bind.

EOU
  exit(1);
}
