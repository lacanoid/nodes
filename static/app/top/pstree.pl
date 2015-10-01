#!/usr/bin/perl

use JSON;

my $j = JSON->new->pretty;
my $ps = `ps -e --no-headers -o pid,ppid,ucmd`;
my @lines = split(/\n/,$ps);
my %p;

for my $l (@lines) {
    if($l=~/^\s*(\d+)\s+(\d+)\s+(.+)$/) {
#	print "$l\n";
	my ($pid,$ppid,$ucmd)=($1,$2,$3);
	$p{$pid}={name=>$ucmd};
	if(!$p{$ppid}->{children}) { $p{$ppid}->{children}=[]; }
	push @{$p{$ppid}->{children}}, $p{$pid};
    }
}

print $j->encode($p{1});
print "\n";
