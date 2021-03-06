#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

use Net::Twitter;

my $data_directory = "twitter_backup";

mkdir $data_directory;

# Initialize Twitter connections
my $nt = Net::Twitter->new(
    traits          => ['API::REST', 'OAuth'],
    consumer_key    => "scHFkZoI9hkUzs980rTuOA",
    consumer_secret => "XzvzzVdzomTk9R2ZTkyilcl2EW7ZGN2hNTgNcB4bs",
);
if( not defined($nt) or $@ ) {
	die "Could not create Twitter connection! " . $@ . "\n";
}

#OAuth portion
if(open(TOKENFILE, "<$data_directory/oauth_token")){
    while(<TOKENFILE> =~ /^(.+?)=(.+)$/){
	if($1 eq "TOKEN"){
	    $nt->access_token($2);
	}elsif($1 eq "SECRET"){
	    $nt->access_token_secret($2);
	}
    }
    close(TOKENFILE);
}

unless ( $nt->authorized ) {
    print "Authorize this app at ", $nt->get_authorization_url, " and enter the PIN\n";
    my $pin = <STDIN>; chomp $pin;
    my($access_token, $access_token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => $pin);
    print "TOKEN = $access_token - SECRET = $access_token_secret \n";
    
    if(open(TOKENFILE, ">$data_directory/oauth_token")){
	print TOKENFILE "TOKEN=$access_token\n";
	print TOKENFILE "SECRET=$access_token_secret\n";
	print "written to $data_directory/oauth_token \n";
    }    
}

# Read last id
my $high_water='1';
if(open(IDFILE, "<$idfile")){
    $high_water = <IDFILE>;
}
chomp($high_water);
close(IDFILE);

# Open output file
open(BAKFILE, ">>$data_directory/twitter-current") or die "Write error log file! $!\n";
binmode BAKFILE, ":utf8";

# Open lastid file
open(IDFILE, ">$data_directory/lastid") or die "Write error lastid! $!\n";

my $firstid = '';
my $lastid = '';
my $returns = 200;
my $countimported = 0;

eval {

	my $statuses = $nt->friends_timeline({ since_id => $high_water, count => $returns, include_rts => '1' });

        #for my $status ( @$statuses ) {
        for my $status ( sort { $a->{id} <=> $b->{id}; } @$statuses ) {
            if ( $firstid eq '') { $firstid = $status->{'id'}; }
            $lastid = $status->{'id'};
            print BAKFILE "$status->{created_at} <$status->{user}{screen_name}> $status->{text} [$status->{id}]\n";
	    $countimported++;
        }
    };

# Write last id
if ($lastid ne '' ) { print IDFILE $lastid; }
else { print IDFILE $high_water; }

close(BAKFILE);
close(IDFILE);

# Print report
print "$countimported Tweets imported in this run (begin from $firstid, end to $lastid).\n"; 
