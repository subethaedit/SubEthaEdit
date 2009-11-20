#!/usr/bin/perl
#
#my $intro = "\nperlproxy15 - implementasi komplit proxy HTTP/1.1 ".
"[model select non-blocking low-buffering]"; print "$intro\n"; 
#
#my $author="Copyright (c) 2000 Dody Suria Wijaya"; print "$author\n\n";

# Not yet implemented:
# 1. count time-out for persistent connection
# 4. enable low-buffering transfer for chunked body
# 5. Access list
# 6. Advertisements blocking

use strict;
use IO::Socket;
use IO::Select;
use POSIX qw(F_SETFL O_NONBLOCK EAGAIN EPIPE);
use vars qw/$opt_d $opt_o $opt_p %st %debug/;

## uncomment below to get reliable localhost name (but memory consuming)
#use Sys::Hostname; my $hostname = hostname();
#my $MYIP = gethostbyname($hostname) or die "Couldn't resolve $hostname: $!";
#$MYIP = inet_ntoa($MYIP);

my $MYIP = `uname -n`; $MYIP =~ s/\n//;

use Getopt::Std;
#d = debug, p = next hop proxy address:port, o = this proxy port
getopts('dp:o:'); 

# declare global var
my $VERSION = "1.5.2";
my $sl_read = new IO::Select;
my $sl_write = new IO::Select;
my $port = $opt_o? $opt_o : 8888;
my $proxy = $opt_p if defined $opt_p;
my $viastring = "1.1 legalif proxymultiplekser";
my %reason = (500=>'Internal Server Error',501=>'Not Implemented',502=>'Bad Gateway', 503=>'Service Unavailable',504=>'Gateway Timeout', 505=>'HTTP Version Not Supported',400=>'Bad Request');
my @sensors = qw/sex xxx porno cewek/;
my @sensors2 = qw/norak kampung linux client server proxy basic/;
# maximum non-blocking sysread/syswrite iteration per client per request
# low for high reaction but slow passing, high for potentially low reaction but faster passing
my $max_iter = 3; 

my $aut = 0; # set 1 to enable authentication
my $aut_cre = "dody:rahasia"; #username password for proxy authentication
my $max_buffering = 1024*128; #maximum length of data read/write for each iteration
my $html_filter = 0; # enable (1) for substituting html body message text
my $non_block = 1; # just for testing, should not be changed from (1)

# declare subroutine prototype
sub debug ($$;$);
sub quickresp ($$$);
sub decode_b64 ($);
sub clientclose ($);
sub serverclose ($);
sub showcommand ($); 
sub htmlfilter ($);

# trap sigpipe (generated when reading/writing already closed socket)
$SIG{'PIPE'} = 'IGNORE';

# creating listening socket
my $mainsocket = new IO::Socket::INET (LocalHost=>$MYIP,LocalPort=>$port,Proto=>'tcp',
				       Listen=>10,Reuse=>1) or die $!;
print "Socket created at $MYIP:$port\n"; 
undef $MYIP;
$sl_read->add($mainsocket);
$sl_read->add(\*STDIN);

# main loop, other client must wait until operation has return to select
MAINLOOP: while (1) { #main loop
  # blocks here until something on the end of the connection 
  my ($aref_read, $aref_write) = IO::Select->select($sl_read,$sl_write,undef);

 READ_FHS: foreach my $sck (@$aref_read) { # serve readable handles

    if ($sck == $mainsocket) { # request to connect from client
      my $sock = $sck->accept();
      fcntl $sock, F_SETFL(), O_NONBLOCK() if $non_block; # make it non-blocking
      $st{$sock}{peerhost} = join "", $sock->peerhost(), ":", $sock->peerport();
      debug localtime(time)." - Session debugging for Client ($st{$sock}{peerhost})",$sock;
      debug "#select# => main socket readable",$sock,1;
      debug "Accepting connection from Client $st{$sock}{peerhost}...", $sock;
      $sl_read->add($sock);
      # set default var
      $st{$sock}{tipe} = 1; # 1 is Client connection
      $st{$sock}{mark} = 1; # socket has not been read/write
      $st{$sock}{persist} = 1; # connection persistance default to on
    }
    
    elsif($sck == \*STDIN) {
      showcommand $sck;
    }
    elsif ($st{$sck}{tipe} == 1) { # Client bisa dibaca
      debug "#select# => Client readable",$sck,1;
      my $buffer;
      while (1) {
	my $byte_read = sysread $sck, $buffer, $max_buffering;
	if (defined $byte_read) {
	  debug "Client->Proxy ($byte_read bytes)",$sck;
	  if ($byte_read == 0) { # remote client/server just closed the connection?
	    debug "Client closed the connection",$sck;
	    clientclose $sck;
	    next READ_FHS;
	  }
	  else {
	    $st{$sck}{req} .= $buffer;
	  }	    
	}
	elsif ($! == EAGAIN()) { # socket buffer empty
	  debug "Client too slow, skipping... (non-blocking)",$sck;
	  last;
	}
	else { # anything elses...
	  debug "Client connection error",$sck;
	  clientclose $sck;
	  next READ_FHS;
	}
      }
      debug "Parsing header...", $sck;      
      if ($st{$sck}{mark} == 1) { # get request line
	while (1) { # skip crlf before start-line
	  unless ($st{$sck}{req} =~ s/^([^\r]*\r\n)//) {
	    debug "Client send partial request line header...getting some more", $sck;
	    next READ_FHS;
	  }
	  $buffer = $1;
	  $st{$sck}{req_orig} .= $buffer;
	  last if $buffer ne "\r\n";
	}
	# parse request start-line
	if ($buffer =~ /^(\w+)\s+([^\s]+)\s+([^\s]+)/) {
	  $st{$sck}{metode} = $1; 
	  $st{$sck}{uri} = $2; 
	  $st{$sck}{versi} = $3; $st{$sck}{persist} = 0 if $3 ne "HTTP/1.1";
	  $st{$sck}{uri} =~ m|^((\w*)://)?(.*?)(:(\d*))?(/.*)?$|; 
	  $st{$sck}{uri_scheme} = $2; 
	  $st{$sck}{uri_hostname} = $3; 
	  $st{$sck}{uri_port} = $5 ? $5 : "80"; 
	  $st{$sck}{uri_abspath} = $6 ? $6 : "/";
	}
	else {
	  quickresp 400, "Bad Request Start-line: $buffer", $sck;
	  $st{$sck}{persist} = 0;
	  next READ_FHS;
	}	
	if ($st{$sck}{uri_hostname} eq "!config") { # pure GNU, anyone may see the source code
	  my $haha = `cat $0`;
	  $haha =~ s/</&gt;/g;
	  $haha =~ s/>/&lt;/g;
	  quickresp 200,"Here's the source code of this program:\n</h3><pre>$haha</pre>",$sck;
	  $st{$sck}{persist} = 0;
	  next READ_FHS;
	}	
	if ($st{$sck}{uri_hostname} eq "") {
	  quickresp 400,"You need to give absolute URI",$sck;
	  $st{$sck}{persist} = 0;
	  next READ_FHS;
	}

	for my $word (@sensors) { # access rule by URI
	  if ( $st{$sck}{uri} =~ /$word/i) {
	    quickresp 400,"Access blocked by URI ($st{$sck}{uri})",$sck;
	    next READ_FHS;
	  }
	}
	
	# build request line using URI rule
	$st{$sck}{req_line} = join "", $st{$sck}{metode}," ", $proxy ?
	                      $st{$sck}{uri} : 
                              $st{$sck}{uri_abspath},
                              " ", "HTTP/1.1\r\n";
	$st{$sck}{mark} = 2;
      }

      if ($st{$sck}{mark} == 2) { # get request field header
	while (1) { 
	  unless ($st{$sck}{req} =~ s/^([^\r]*\r\n)//) {
	    debug "Client send partial field header...getting some more", $sck;
	    next READ_FHS;
	  }
	  $buffer =  $1;
	  last if $buffer eq "\r\n";  
	  $st{$sck}{req_orig} .= $buffer;
	  # removing request field-line
	  next if $buffer =~ /^Connection:/i; 
	  next if $buffer =~ /^Proxy-Connection:/i;
	  $st{$sck}{req_fields} .= $buffer;
	  }	
	$st{$sck}{req_fields}||=""; 
	
	# Virtual host rule
	if ($st{$sck}{req_fields} !~ /^Host:/im) {
	  $st{$sck}{req_fields} .= "Host: $st{$sck}{uri_hostname}:$st{$sck}{uri_port}\r\n";
	}
	
	# Persistent connection rule
	if ($st{$sck}{versi} ne "HTTP/1.1" or 
	    $st{$sck}{req_orig} =~ /^Connection:\s*close/im ) {
	  $st{$sck}{persist} = 0; # disable koneksi persistent
	}
	
	# Proxy authentication rule
	if ( $aut and 
	     ( $st{$sck}{req_fields} !~ /^Proxy-Authorization:\s*(\S*)\s*(\S*)/im or 
	       decode_b64($2) ne $aut_cre)) {
	  $st{$sck}{resp} = "HTTP/1.1 407 Proxy Authorization\r\nProxy-Authenticate: Basic realm=\"legalif/11\"\r\nVia: $viastring\r\nConnection: close\r\n\r\n";
	  $st{$sck}{resp_len} = length $st{$sck}{resp};
	  $sl_read->remove($sck);
	  $sl_write->add($sck);
	  next READ_FHS;
	}
	
	# OPTIONS method rule
	if ( $st{$sck}{metode} eq "OPTIONS" and 
	     ( $st{$sck}{uri} eq "*" or $st{$sck}{req_fields} =~ /^Max-Forwards:\s*0/im)) {
	  $st{$sck}{resp} = "HTTP/1.1 200 OK\r\nAllow: GET, HEAD, POST, PUT, OPTION, TRACE\r\nVia: $viastring\r\nConnection: close\r\nContent-Length: 0\r\n\r\n";
	  $st{$sck}{resp_len} = length $st{$sck}{resp};
	  $sl_read->remove($sck);
	  $sl_write->add($sck);
	  next READ_FHS;
	}
	
	# TRACE method rule
	if ( $st{$sck}{metode} eq "TRACE" and 
	     ( $st{$sck}{uri} eq "*" or $st{$sck}{req_fields} =~ m/^Max-Forwards:\s*0/im)) {
	  my $len = length $st{$sck}{req_orig};
	  $st{$sck}{resp} = "HTTP/1.1 200 OK\r\nContent-Type: message/http\r\nVia: $viastring\r\nConnection: close\r\nContent-Length: $len\r\n\r\n$st{$sck}{req_orig}";
	  delete $st{$sck}{req_orig};
	  $st{$sck}{resp_len} = length $st{$sck}{resp};
	  $sl_read->remove($sck);
	  $sl_write->add($sck);
	  next READ_FHS;
	}
	delete $st{$sck}{req_orig};
	
	# add new request fields
	$st{$sck}{req_fields} .= "Via: $viastring\r\nConnection: close\r\n";

	# POST and PUT method handler
	if ( ($st{$sck}{metode} eq "POST" or $st{$sck}{metode} eq "PUT") and 
	     $st{$sck}{req_fields} =~ m/^Content-Length:\s*(\S*)/im ) {
	  $st{$sck}{req_bodylen} = $1;
	}
     
	$st{$sck}{mark} = 3;
      }
      if ($st{$sck}{mark} == 3) { # finale phase
	if (defined $st{$sck}{req_bodylen}) { # get body client (if available)
	   if ($st{$sck}{req_bodylen} > length($st{$sck}{req})) {
	     debug "Client send partial body...getting some more",$sck;
	     next READ_FHS;
	   }
	}
	debug "Request message complete",$sck;
	debug "Connecting to Server ($st{$sck}{uri_hostname}:$st{$sck}{uri_port})",$sck;
	$st{$sck}{req} = join "", $st{$sck}{req_line}, $st{$sck}{req_fields}, "\r\n", $st{$sck}{req};
	$st{$sck}{req_len} = length $st{$sck}{req};
	$st{$sck}{req_offset} = 0;
	delete $st{$sck}{req_line};
	delete $st{$sck}{req_fields};
	my $sck2;
	if ($proxy) {
	  $sck2 = new IO::Socket::INET (PeerAddr => $proxy, Proto => 'tcp');
	}
	else {
	  $sck2 = new IO::Socket::INET (PeerAddr => $st{$sck}{uri_hostname}, 
					PeerPort => $st{$sck}{uri_port}, 
					Proto => 'tcp');
	}
	if ($sck2) {
	  fcntl $sck2, F_SETFL(), O_NONBLOCK() if $non_block; # non-block-kan
	  # prepare select to write Server
	  $sl_read->remove($sck); 
	  $sl_write->add($sck2);
	  $st{$sck2}{ch} = $sck; $st{$sck}{ch} = $sck2; #exchange socket name
	  $st{$sck2}{tipe} = 2; # 2 is Server connection
	  $st{$sck2}{peerhost} = "$st{$sck}{uri_hostname}:$st{$sck}{uri_port}";
	  $st{$sck}{mark} = 1;
	  debug "Connected to Server",$sck;
	}
	else {
	  $@ =~ /INET:(.*)$/;
	  debug "Connecting to Server error: $1",$sck;
	  quickresp 502, $1, $sck;
	  next READ_FHS;
	}
      }
    }
    elsif ($st{$sck}{tipe} == 2) { # Server is ready to read
      debug "#select# => Server readable",$sck,1;
      
      # let's read Server until Server closes the connection
      my $buffer; 
      my $index = 0;
      my $byte_read;
      while (1) {
	++$index;
	if ($index > $max_iter) {
	  debug "$max_iter iteration reached...going to next task",$sck;
	  last;
	}
	$byte_read = sysread $sck, $buffer, $max_buffering;
	if (defined $byte_read) {
	  if ($byte_read == 0) {  
	    # Server just closed the connection. This may be the result of 2 options:
	    # 1. Message has been transmitted fully, or
	    # 2. Some part of the message has been transmitted.
	    # For now, let's assume that the server transmission is reliable (option 1)
	    debug "Server closed the connection (end of response message)",$sck;
	    last;
	  }
	  debug "Server->Proxy ($byte_read bytes)",$sck;
	  $st{$st{$sck}{ch}}{resp} .= $buffer;
	  $st{$st{$sck}{ch}}{resp_len} += $byte_read;
	}
	elsif ($! == EAGAIN()) { #socket buffer empty
	  debug "Server is too slow, skipping... (non-blocking)",$sck;
	  last;
        }
	else { # if anything else, cleanup server connection, tell client about it, and cleanup client too
	  debug "Server connection error",$sck;
	  quickresp 502,"Connection to server broke when reading", $sck;
	  serverclose $sck;
	  next READ_FHS;
	}
      }
      $st{$sck}{mark} ||= 1;
      if ($st{$sck}{mark} == 1) {      
      debug "Parsing header...", $sck;
	while (1) {    # skip crlf before start-line
	  unless ($st{$st{$sck}{ch}}{resp} =~ s/^([^\r]*\r\n)//) {
	    clientclose $sck if $byte_read == 0;
	    next READ_FHS;
	  }
	  $buffer =  $1;
	  last if $buffer ne "\r\n";
	}
	$st{$st{$sck}{ch}}{resp_line} = $buffer;
	$st{$sck}{mark} = 2;
      }
      if ($st{$sck}{mark} == 2) {
      debug "Parsing header...", $sck;
	while (1) {      # loop for picking each field-line
	  unless ($st{$st{$sck}{ch}}{resp} =~ s/^([^\r]*\r\n)//) {
	    clientclose $sck if $byte_read == 0;
	    next READ_FHS;
	  }
	  $buffer = $1;
	  last if $buffer eq "\r\n";
	  next if $buffer =~ /^Connection:/im; # Remove connection field
	  # chunked to normal rule
	  if ($buffer =~ /^Transfer-Encoding:\s*chunked/im and 
	      $st{$st{$sck}{ch}}{versi} ne "HTTP/1.1") { 
	    $st{$sck}{chunked} = "";
	    next;
	  }
	  $st{$st{$sck}{ch}}{resp_fields} .= $buffer;
	}
	
      # add new response fields 
	$st{$st{$sck}{ch}}{resp_fields} .= "Via: $viastring\r\n";
	$st{$st{$sck}{ch}}{resp_fields} .= "Connection: close\r\n" 
	  if ($st{$st{$sck}{ch}}{persist} == 0);
	
	if (!defined $st{$sck}{chunked}) {
	  $st{$st{$sck}{ch}}{resp} = join "", $st{$st{$sck}{ch}}{resp_line}, 
	    $st{$st{$sck}{ch}}{resp_fields}, "\r\n", $st{$st{$sck}{ch}}{resp};
	  $st{$st{$sck}{ch}}{resp_len} = length $st{$st{$sck}{ch}}{resp};
	}
	else {
	  debug "Response body is chunked, disabling fast-passing....decoding... ", $sck;
	}
	$st{$sck}{mark} = 3;
      }
      if ($st{$sck}{mark} == 3) { # fase 3 is action after parsing the header
	if (defined $st{$sck}{chunked}) { #chunked to body rule 
	  unless (defined($byte_read) and $byte_read == 0) { # FORCE GETTING ALL DATA FIRST
	    debug "Partial body detected...getting more to select",$sck; 
	    next READ_FHS;
	  }
	  if ($st{$st{$sck}{ch}}{resp} =~ s/^\W*(\w*)\W*\r\n//) {
	    $st{$sck}{chunked} = hex $1;
	  }
	  else { #something wrong with the chunked body
	    debug "Error decoding chunked...closing connection",$sck;
	    quickresp 502,"Error decoding chunked body", $sck;
	    serverclose $sck;	    
	    next READ_FHS;
	  }
	  while ($st{$sck}{chunked} > 0) {
	    $st{$sck}{chunked_buff} .= substr( $st{$st{$sck}{ch}}{resp}, 0, $st{$sck}{chunked});
	    $st{$st{$sck}{ch}}{resp} = substr( $st{$st{$sck}{ch}}{resp}, $st{$sck}{chunked}+2);
	    if ($st{$st{$sck}{ch}}{resp} =~ s/^\W*(\w*)\W*\r\n//) {
	      $st{$sck}{chunked} = hex $1;
	    }
	    else { #something wrong with the chunked body
	      debug "Error decoding chunked",$sck;
	      quickresp 502,"Error decoding chunked body",$sck;
	      serverclose $sck;
	      next READ_FHS;
	    }
	  }
	  # html filter
	  if ($html_filter and $st{$st{$sck}{ch}}{resp_fields} =~ m|^Content-Type:\s*text/html|im) {
	    debug "Filtering HTML...", $sck;
	    htmlfilter \$st{$sck}{chunked_buff};
	  }
	  $st{$st{$sck}{ch}}{resp_fields} .= join "", "Content-Length: ", length($st{$sck}{chunked_buff}), "\r\n";
	  $st{$st{$sck}{ch}}{resp} = join "",$st{$st{$sck}{ch}}{resp_line}, $st{$st{$sck}{ch}}{resp_fields}, "\r\n", $st{$sck}{chunked_buff};
	  delete $st{$sck}{chunked_buff};
	  $st{$st{$sck}{ch}}{resp_len} = length $st{$st{$sck}{ch}}{resp};
	  $st{$st{$sck}{ch}}{resp_offset} = 0;

	  $sl_write->add($st{$sck}{ch});
	  serverclose $sck;
	}
	elsif (defined($byte_read) and $byte_read == 0) { # No more data from server
	  $st{$st{$sck}{ch}}{resp_offset} = 0;	  
	  if ($html_filter and $st{$st{$sck}{ch}}{resp_fields} =~ m|^Content-Type:\s*text/html|im) {
	    debug "Filtering HTML2...", $sck;
	    htmlfilter \$st{$st{$sck}{ch}}{resp};
	  }
	  # prepare select to write client
	  $sl_write->add($st{$sck}{ch});
	  serverclose $sck;
	}
	else { # header is sent but there're still data
	  if ($html_filter and $st{$st{$sck}{ch}}{resp_fields} =~ m|^Content-Type:\s*text/html|im) { # html filter
	    debug "Filtering HTML2...", $sck;
	    htmlfilter \$st{$st{$sck}{ch}}{resp};
	  }

	  # Fast passing method
	  # prepare select to write Client
	  $sl_read->remove($sck); 
	  $sl_write->add($st{$sck}{ch}); 
	  $st{$st{$sck}{ch}}{resp_offset} = 0;
	  debug "Fast-Passing to Client", $sck;
	}
      }
    }
  }

 WRITE_FHS: for my $sck (@$aref_write) { # let's server writable handles

    if ($st{$sck}{tipe} == 2) { # Server is ready to write
      debug "#select# => Server writeable",$sck,1;
      my $index = 0;
      my $byte_written;
      while (1) {	
	last if $st{$st{$sck}{ch}}{req_len} <= 0;
	++$index;
	if ($index > $max_iter) {
	  debug "$max_iter iteration reached, switching task",$sck;
	  next WRITE_FHS;
	}
	$byte_written = syswrite $sck, $st{$st{$sck}{ch}}{req}, $st{$st{$sck}{ch}}{req_len}, $st{$st{$sck}{ch}}{req_offset};
	if (defined $byte_written ) {
	  if ($byte_written == 0) { # remote client/server just closed the connection
	    debug "Server closed then connection when sending to Server",$sck;
	    quickresp 502,"Connection to server broke when writing", $sck;
	    serverclose $sck;
	    next WRITE_FHS;
	  }
	  debug "Proxy->Server ($byte_written bytes)",$sck;
	  $st{$st{$sck}{ch}}{req_len} -= $byte_written;
	  $st{$st{$sck}{ch}}{req_offset} += $byte_written;
	}
	elsif ($! == EAGAIN()) { #server overloaded, return later to finish sending request
	  debug "Server overloaded, skipping... (non-blocking)",$sck;
	  next WRITE_FHS; #this loop
	}
	else { # Something weird happens
	  debug "Server connection error when sending to Server",$sck;
	  quickresp 502,"Connection to server broke when writing",$sck;
	  serverclose $sck;
	  next WRITE_FHS;
	}
      }

      #prepare select to read srver
      $sl_write->remove($sck);
      $sl_read->add($sck);
    }

    elsif ($st{$sck}{tipe} == 1) { #Client is ready to write
      debug "#select# => Client writeable",$sck,1;
      my $index = 0;
      my $byte_written;
      $st{$sck}{resp_offset} ||= 0; # give default value
      while (1) {
	++$index;
	if ($index > $max_iter) {
	  debug "$max_iter iteration reached...going to next task",$sck;	  
	  next WRITE_FHS;
	}
	if ($st{$sck}{resp_len} <= 0) { # if finish writing data, get some more from server
	  # if server connection is dead, let's assume no more data from server
	  last if (!defined $st{$sck}{ch}) or (!defined $st{$st{$sck}{ch}}); # 
	  # prepare select to read server
	  $sl_write->remove($sck); 
	  $sl_read->add($st{$sck}{ch});
	  # reset these var
	  $st{$sck}{resp} = ""; 
	  $st{$sck}{resp_len} = 0;
	  next WRITE_FHS;
	}
	$byte_written = syswrite $sck, $st{$sck}{resp}, $st{$sck}{resp_len}, $st{$sck}{resp_offset};
	if (defined $byte_written ) {
	  debug "Proxy->Client ($byte_written bytes)",$sck;
	  $st{$sck}{resp_len} -= $byte_written;
	  $st{$sck}{resp_offset} += $byte_written;
	  if ($byte_written == 0) { #client closes its connection
	    debug "Client closed the connection",$sck;
	    clientclose $sck;
	    next WRITE_FHS;
	  }
	}
	elsif ($! == EAGAIN()) { #client overloaded, return later to finish sending request
	  debug "Client overloaded, skipping... (non-blocking)",$sck;
	  next WRITE_FHS;
	}
	elsif ($! == EPIPE()) { #client connection has disappeared!
	  debug "Client connection abruptly closed",$sck;
	  clientclose $sck;
	  next WRITE_FHS;
	}
	else { # something else happens
	  debug "Client connection error",$sck;
	  clientclose $sck;
	  next WRITE_FHS;
	}
      }
      # Client writing finished.
      $sl_write->remove($sck); # nothing to write
      if ($st{$sck}{persist}) {
	debug "Persistent on, waiting more request from Client",$sck;
	delete $st{$sck}; #remove all request/response dependent variables
	# ..but keep this var
	$st{$sck}{tipe} = 1; 
	$sl_read->add($sck);
	$st{$sck}{peerhost} = join "", $sck->peerhost(), ":", $sck->peerport();
	# reset session var to default
	$st{$sck}{mark} = 1; 
	$st{$sck}{persist} = 1; 
      }
      else {
	debug "Pesistent is off",$sck;      
	clientclose $sck;
      }
    }
  }
}

sub quickresp ($$$) { # generate response message for some errors
  my ($code, $body, $socket) = @_;
  my $nowis = localtime(time);
  debug "Error: $code $body", $socket;
  $sl_read->remove($socket); $sl_write->remove($socket); # remove both just to make sure
  $socket = $st{$socket}{ch} if $st{$socket}{tipe} == 2; # if server use this subroutine
  $st{$socket}{resp} = <<STOP;
HTTP/1.1 $code $reason{$code}\r
Content-type: text/html\r
Connection: close\r
\r
<html>
  <head>
    <title>$code $reason{$code}</title>
  </head>
  <body>
  <h1>$code $reason{$code}</h1>
  <h3>$body</h3>
  <hr>
  <p>Message generated at $nowis</p>
  <p><b>proxymultiplexer12</b> by Dody Suria Wijaya - <a href=mailto:>dody\@neuk.net</a></p>
  </body>
</html>
STOP
  $st{$socket}{resp_len} = length $st{$socket}{resp};
  $sl_write->add($socket);
  return 1;
}  

sub debug($$;$) { # argumens are message text, socket, and indents (optional)
  return unless $opt_d;
  my $message = shift;
  my $socket = shift;
  my $indent = shift;
  $indent||=10;
  $socket = $st{$socket}{ch} if $st{$socket}{tipe} == 2; # if this subroutine argument socket is a server socket
  if (defined $debug{$socket}) {
    $message = " "x$indent.$message;
  }
  else {    
    my $line = "=" x length $message;
    $message = "$line\n$message\n$line";
  }
  $debug{$socket} .= $message."\n";
  return 1;
}

sub serverclose ($) { #argumen is ref to server connection
  my $sck = shift;
  debug "Closing Server connection...", $sck;
  $sl_read->remove($sck);
  $sl_write->remove($sck);
  delete $st{$sck};
  close $sck;
}

sub clientclose($) { #argumen is ref to client connection
  my $sck = shift;
  serverclose $st{$sck}{ch} if defined $st{$st{$sck}{ch}};
  debug "Closing Client connection...", $sck;
  print $debug{$sck};
  delete $debug{$sck};
  $sl_read->remove($sck);
  $sl_write->remove($sck);
  delete $st{$sck};
  close $sck;
  return 1;
}

sub decode_b64 ($) { # taken from MIME::Base64
    my $str = shift;
    my $res = "";
    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    return if (length($str) % 4);
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    while ($str =~ /(.{1,60})/gs) {
	my $len = chr(32 + length($1)*3/4); # compute length byte
	$res .= unpack("u", $len . $1 );    # uudecode
    }
    return $res;
}

sub htmlfilter ($) { #argumen is reference to string
  my $ref_body = shift;
    for my $word (@sensors2) {
      $$ref_body =~ s|($word)|<font color=red>$1</font>|ig;
    }
  return 1;
}

sub showcommand ($) {
  my $sck = shift;
  my $buffer;
  my $byte_read = sysread $sck, $buffer, $max_buffering;
  chomp $buffer;
  if ($buffer eq "h") {
    print <<STOP;
Command: 
a - active connection
r - readable handles
w - writeable handles
d - toggle debugging
s - statistics
q - quit
h - this help
STOP
}
  elsif ($buffer eq "r") {
    for my $hd ($sl_read->handles) {
      if ($hd == $mainsocket) {
	print " main socket\n";
      }
      elsif (defined $st{$hd}) {
	print " $st{$hd}{peerhost}\n";
      }	 
    }
  }
  elsif ($buffer eq "w") {
    for my $hd ($sl_write->handles) {
      if (defined $st{$hd}) {
	print " $st{$hd}{peerhost}\n";
      }	 
    }
  }
  elsif ($buffer eq "q") {
    print "Have a nice day...\n";
    exit;
  }
  elsif ($buffer eq "d") {
    $opt_d = $opt_d? 0: 1;
    print "debugging: $opt_d\n";
  }
  elsif ($buffer eq "s") {
    
  }
  elsif ($buffer eq "n") {
    $non_block = $non_block? 0: 1;
    print "non-blocking: $non_block\n";
  }
  return 1;
}

__END__

=head1 NAME

httpproxy - complete HTTP/1.1 proxy implementation

=head1 SYNOPSIS

httpproxy [-d] [-p] [-o]

=head1 DESCRIPTION

Httpproxy is an implementation of HTTP/1.1 proxy from RFC2618. It uses
B<select non-blocking>, so that it's a one process software. It also
uses B<fast passing> method to pass message before the message
completes to conserve memory and increase the reaction time (time
needed for the first byte of message to reach destination).  Httpproxy
source is also available without comments and debugging statements to
conserve memory and increase speed. You can get it at the same place
as this script, with file name L<httpproxynd>.

=head1 OPTIONS

=over 4

=item B<-d>

Verbose on for debugging purpose

=item B<-p>

The following argument is a IP:port string of the intermediary Proxy
(another Proxy which httpproxy uses to connect to server). Default to
not using intermediary Proxy. Example: proxy.rad.net.id:3128

=item B<-o>

The following argument is the port number which httpproxy
uses. Default to 8888. Example: 3128.

=back

=head1 BUGS

=item 1. Potential blocking when trying to connect to Server.

=item 2. Memory leak caused by perl mystery.

=head1 SEE ALSO

L<httpproxynd>.

=head1 AUTHOR

Dody Suria Wijaya <dody@neuk.net>

=head1 COPYRIGHT

Copyright (c) 2000 Dody Suria Wijaya. All right reserved.  This
program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=pod OSNAMES

Linux

=pod SCRIPT CATEGORIES

Networking
Web

=cut
