#!/usr/bin/perl

# largely taken verbatim from
# http://search.cpan.org/dist/Net-Twitter/lib/Net/Twitter/Role/OAuth.pm

# Next step is to get the keys and secrets to a config.

# you need to get your own access token and secret (which identifies you
# as a developer or application) and consumer key and secret (which
# identifies you as a Twitter user). You cannot use mine.

use 5.010 ;
use strict ;
use IO::Interactive qw{ interactive } ;
use Net::Twitter ;
use Carp ;

my $status = join ' ', @ARGV ;
if ( length $status < 1 ) {
    while ( <STDIN> ) {
        $status .= $_ ;
        }
    chomp $status ;
    }

if ( length $status > 140 ) {
    say { interactive } 'Too long' ;
    say { interactive } length $status ;
    exit ;
    }
if ( length $status < 1 ) {
    say { interactive } 'No content' ;
    say { interactive } length $status ;
    exit ;
    }

say $status ;

# GET key and secret from http://twitter.com/apps
my $twit = Net::Twitter->new(
        traits          => [ 'API::REST', 'OAuth' ],
        consumer_key    => 'consumer_key' ,   #GET YOUR OWN
        consumer_secret => 'consumer_secret', #GET YOUR OWN
        ) ;

# You'll save the token and secret in cookie, config file or session database
my ( $access_token, $access_token_secret ) ;
( $access_token, $access_token_secret ) = restore_tokens() ;

if ( $access_token && $access_token_secret ) {
    $twit->access_token( $access_token ) ;
    $twit->access_token_secret( $access_token_secret ) ;
    }

unless ( $twit->authorized ) {

    # You have no auth token
    # go to the auth website.
    # they'll ask you if you wanna do this, then give you a PIN
    # input it here and it'll register you.
    # then save your token vals.

    say "Authorize this app at ", $twit->get_authorization_url, ' and enter the PIN#' ;
    my $pin = <STDIN> ;    # wait for input
    chomp $pin ;
    my ( $access_token, $access_token_secret, $user_id, $screen_name ) =
      $twit->request_access_token( verifier => $pin ) ;
    save_tokens( $access_token, $access_token_secret ) ;    # if necessary
    }

if ( $twit->update( $status ) ) {
    say { interactive } 'OK' ;
    }
else {
    say { interactive } 'FAIL' ;
    }

#========= ========= ========= ========= ========= ========= =========

# Docs-suggested
sub restore_tokens {
    my $access_token = 'token' ;            #GET YOUR OWN
    my $access_token_secret = 'secret' ;    #GET YOUR OWN
    return $access_token, $access_token_secret ;
    }

sub save_tokens {
    my ( $access_token, $access_token_secret ) = @_ ;
    say 'access_token: ' . $access_token ;
    say 'access_token_secret: ' . $access_token_secret ;
    return 1 ;
    }
