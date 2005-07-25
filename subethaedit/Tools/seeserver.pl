 #!/usr/bin/perl -w
 use IO::Socket;
 use Net::hostent;              # for OO version of gethostbyaddr

 $PORT = 4242;                  # pick something not in use
 $server = IO::Socket::INET->new( Proto     => 'tcp',
                                  LocalPort => $PORT,
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1);

 die "can't setup server" unless $server;
 print "[Server $0 accepting clients]\n";

while ($client = $server->accept()) {
    $client->autoflush(1);
    print $client "Welcome to SubEthaRemote. Type help for command list.\n";
    $hostinfo = gethostbyaddr($client->peeraddr);
    printf "[Connect from %s]\n", $hostinfo->name || $client->peerhost;
    print $client "see> ";
    while ( <$client>) {
        next unless /\S/;       # blank line
        if (/quit|exit|bye/i) { last; }
        elsif (/ls/i ) { 
            @documents = split /,/,`osascript -e 'tell application "SubEthaEdit" to return documents'`;
            foreach $document (@documents) {
                chomp($document);
                $document =~ s/^ *text document //g;
                $access = `osascript -e 'tell application "SubEthaEdit" to return access control of text document named "$document"'`;
                if ($access =~ /locked/) {$r="-";$w="-";}
                if ($access =~ /read write/) {$r="r";$w="w";}
                if ($access =~ /read only/) {$r="r";$w="-";}
                
                $announced = `osascript -e 'tell application "SubEthaEdit" to return announced of text document named "$document"'`;
                if ($announced =~ /false/) {$a="-";} else {$a="a";}

                print $client "$a$r$w $document\n";
            }
        } elsif (/new/i ) {
            $name = $_;
            $name =~ s/^new //g;
            $name =~ s/[\cM\cJ\n\r]//g;
            `osascript -e 'tell application "SubEthaEdit" to make new text document with properties {name:"$name"}'`;
        } elsif (/close/i ) {
            $name = $_;
            $name =~ s/^close //g;
            $name =~ s/[\cM\cJ\n\r]//g;
            `osascript -e 'tell application "SubEthaEdit" to close text document named "$name"'`;
        } elsif (/share/i ) {
            $name = $_;
            $name =~ s/^share //g;
            $name =~ s/[\cM\cJ\n\r]//g;
            `osascript -e 'tell application "SubEthaEdit" to set announced of text document named "$name" to true'`;
            `osascript -e 'tell application "SubEthaEdit" to set access control of text document named "$name" to read write'`;
        } elsif (/readonly/i ) {
            $name = $_;
            $name =~ s/^readonly //g;
            $name =~ s/[\cM\cJ\n\r]//g;
            `osascript -e 'tell application "SubEthaEdit" to set access control of text document named "$name" to read only'`;
        } elsif (/conceal/i ) {
            $name = $_;
            $name =~ s/^conceal //g;
            $name =~ s/[\cM\cJ\n\r]//g;
            `osascript -e 'tell application "SubEthaEdit" to set announced of text document named "$name" to false'`;
        } else {
            print $client "Commands: ls new close share readonly conceal quit\n";
        }
    } continue {
        print $client "see> ";
    }
    close $client;
}