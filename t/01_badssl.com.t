#!/usr/bin/env perl

use strict;
use Test::More;
use Data::Dumper;
use JSON;

my $tests = 0;

my (
	$out,
	$json,
	$found,
);
# OK
pass("Running testssl.sh against badssl.com to craete a baseline (may take 2~3 minutes)"); $tests++;
my $okout = `./testssl.sh -S -e -U --jsonfile tmp.json --color 0 badssl.com`;
my $okjson = json('tmp.json');
cmp_ok(@$okjson,'>',10,"We have more then 10 findings"); $tests++;

# Expiration
pass("Running testssl against expired.badssl.com"); $tests++;
$out = `./testssl.sh -S --jsonfile tmp.json --color 0 expired.badssl.com`;
like($out, qr/Certificate Expiration\s+expired\!/,"The certificate should be expired"); $tests++;
$json = json('tmp.json');
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "expiration" ) {
		$found = 1;
		like($f->{finding},qr/^Certificate Expiration.*expired\!/,"Finding reads expired."); $tests++;
		is($f->{severity}, "NOT ok", "Severity should be NOT ok"); $tests++;
		last;
    }
}
is($found,1,"We had a finding for this in the JSON output"); $tests++;

# Self signed and not-expired
pass("Running testssl against self-signed.badssl.com"); $tests++;
$out = `./testssl.sh -S --jsonfile tmp.json --color 0 self-signed.badssl.com`;
like($out, qr/Certificate Expiration\s+\d+/,"The certificate should not be expired"); $tests++;
$json = json('tmp.json');
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "expiration" ) {
		$found = 1;
		like($f->{finding},qr/^Certificate Expiration \: \d+/,"Finding doesn't read expired."); $tests++;
		is($f->{severity}, "OK", "Severity should be ok"); $tests++;
		last;
    }
}
is($found,1,"We had a finding for this in the JSON output"); $tests++;

like($out, qr/Chain of trust.*?NOT ok.*\(self signed\)/,"Chain of trust should fail because of self signed"); $tests++;
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "trust" ) {
		$found = 1;
		like($f->{finding},qr/^All certificate trust checks failed/,"Finding says certificate cannot be trusted."); $tests++;
		is($f->{severity}, "NOT ok", "Severity should be NOT ok"); $tests++;
		last;
    }
}
is($found,1,"We had a finding for this in the JSON output"); $tests++;

like($okout, qr/Chain of trust[^\n]*?Ok/,"Chain of trust should be ok"); $tests++;
$found = 0;
foreach my $f ( @$okjson ) {
	if ( $f->{id} eq "trust" ) {
		$found = 1;
		is($f->{finding},"All certificate trust checks passed.","Finding says certificate can be trusted."); $tests++;
		is($f->{severity}, "OK", "Severity should be OK"); $tests++;
		last;
    }
}
is($found,1,"We had a finding for this in the JSON output"); $tests++;

# Wrong host
#pass("Running testssl against wrong.host.badssl.com"); $tests++;
#$out = `./testssl.sh -S --jsonfile tmp.json --color 0 wrong.host.badssl.com`;
#unlike($out, qr/Certificate Expiration\s+expired\!/,"The certificate should not be expired"); $tests++;
#$json = json('tmp.json');
#$found = 0;
#foreach my $f ( @$json ) {
#	if ( $f->{id} eq "expiration" ) {
#		$found = 1;
#		unlike($f->{finding},qr/^Certificate Expiration.*expired\!/,"Finding should not read expired."); $tests++;
#		is($f->{severity}, "ok", "Severity should be ok"); $tests++;
#		last;
#    }
#}
#is($found,1,"We had a finding for this in the JSON output"); $tests++;

# Incomplete chain
pass("Running testssl against incomplete-chain.badssl.com"); $tests++;
$out = `./testssl.sh -S --jsonfile tmp.json --color 0 incomplete-chain.badssl.com`;
like($out, qr/Chain of trust.*?NOT ok\s+\(chain incomplete\)/,"Chain of trust should fail because of incomplete"); $tests++;
$json = json('tmp.json');
$found = 0;
foreach my $f ( @$json ) {
	if ( $f->{id} eq "trust" ) {
		$found = 1;
		like($f->{finding},qr/^All certificate trust checks failed.*incomplete/,"Finding says certificate cannot be trusted."); $tests++;
		is($f->{severity}, "NOT ok", "Severity should be NOT ok"); $tests++;
		last;
    }
}
is($found,1,"We had a finding for this in the JSON output"); $tests++;

# TODO: RSA 8192

# TODO: CBC
#pass("Running testssl against cbc.badssl.com"); $tests++;
#$out = `./testssl.sh -e -U --jsonfile tmp.json --color 0 cbc.badssl.com`;
#like($out, qr/Chain of trust.*?NOT ok\s+\(chain incomplete\)/,"Chain of trust should fail because of incomplete"); $tests++;
#$json = json('tmp.json');
#$found = 0;
#foreach my $f ( @$json ) {
#	if ( $f->{id} eq "trust" ) {
#		$found = 1;
#		like($f->{finding},qr/^All certificate trust checks failed.*incomplete/,"Finding says certificate cannot be trusted."); $tests++;
#		is($f->{severity}, "NOT ok", "Severity should be NOT ok"); $tests++;
#		last;
#    }
#}
#is($found,1,"We had a finding for this in the JSON output"); $tests++;


done_testing($tests);

sub json($) {
	my $file = shift;
	$file = `cat $file`;
	unlink $file;
	return from_json($file);
}