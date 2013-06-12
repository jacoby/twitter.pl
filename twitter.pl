#!/usr/bin/env perl

# largely taken verbatim from
# http://search.cpan.org/dist/Net-Twitter/lib/Net/Twitter/Role/OAuth.pm

# Next step is to get the keys and secrets to a config.

use 5.010 ;
use strict ;
use Carp ;
use Data::Dumper ;
use Encode 'decode' ;
use IO::Interactive qw{ interactive } ;
use Net::Twitter ;
use WWW::Shorten 'TinyURL' ;
use YAML qw{ DumpFile LoadFile } ;

# next step, add Getopt::Long into the mix
my $config_file = $ENV{ HOME } . '/.twitter.cnf' ;
my $config      = LoadFile( $config_file ) ;

my ( $user, @status ) = @ARGV ;
@status = map {
    my $s = $_ ;
    if ( $s =~ m{^http://}i ) {
        $s = makeashorterlink( $s ) ;
        }
    $s ;
    } @status ;

my $status = join ' ', @status ;
if ( length $status < 1 ) {
    $status = <STDIN> ;
    my @status = split /\s/, $status ;
    $user   = shift @status ;
    @status = map {
        my $s = $_ ;
        if ( $s =~ m{^http://}i ) {
            $s = makeashorterlink( $s ) ;
            }
        $s ;
        } @status ;
    $status = join ' ', @status ;
    }

if ( length $status > 140 ) {
    say { interactive } 'Too long' ;
    say { interactive } length $status ;
    say { interactive } $status ;
    exit ;
    }
if ( length $status < 1 ) {
    say { interactive } 'No content' ;
    say { interactive } length $status ;
    say { interactive } $status ;
    exit ;
    }

# GET key and secret from http://twitter.com/apps
my $twit = Net::Twitter->new(
    traits          => [qw/API::RESTv1_1/],
    consumer_key    => $config->{ consumer_key },
    consumer_secret => $config->{ consumer_secret },
    ) ;

# You'll save the token and secret in cookie, config file or session database
my ( $access_token, $access_token_secret ) ;
( $access_token, $access_token_secret ) = restore_tokens( $user ) ;

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

    say "Authorize this app at ", $twit->get_authorization_url,
        ' and enter the PIN#' ;
    my $pin = <STDIN> ;    # wait for input
    chomp $pin ;
    my ( $access_token, $access_token_secret, $user_id, $screen_name ) =
        $twit->request_access_token( verifier => $pin ) ;
    save_tokens( $user, $access_token, $access_token_secret ) ;
    }

if ( $twit->update( $status ) ) {
    say { interactive } $status ;
    }
else {
    say { interactive } 'FAIL' ;
    }

#========= ========= ========= ========= ========= ========= =========

sub restore_tokens {
    my ( $user ) = @_ ;
    my ( $access_token, $access_token_secret ) ;
    if ( $config->{ tokens }{ $user } ) {
        $access_token = $config->{ tokens }{ $user }{ access_token } ;
        $access_token_secret =
            $config->{ tokens }{ $user }{ access_token_secret } ;
        }
    return $access_token, $access_token_secret ;
    }

sub save_tokens {
    my ( $user, $access_token, $access_token_secret ) = @_ ;
    $config->{ tokens }{ $user }{ access_token }        = $access_token ;
    $config->{ tokens }{ $user }{ access_token_secret } = $access_token_secret ;
    DumpFile( $config_file, $config ) ;
    return 1 ;
    }
