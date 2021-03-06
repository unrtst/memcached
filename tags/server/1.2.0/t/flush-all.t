#!/usr/bin/perl

use strict;
use Test::More tests => 11;
use FindBin qw($Bin);
use lib "$Bin/lib";
use MemcachedTest;

my $server = new_memcached();
my $sock = $server->sock;
my $expire;

print $sock "set foo 0 0 6\r\nfooval\r\n";
is(scalar <$sock>, "STORED\r\n", "stored foo");

mem_get_is($sock, "foo", "fooval");
print $sock "flush_all\r\n";
is(scalar <$sock>, "OK\r\n", "did flush_all");

mem_get_is($sock, "foo", undef);
SKIP: {
    skip "flush_all is still only second-granularity.  need atomic counter on flush_all.", 2 unless 0;

    print $sock "set foo 0 0 3\r\nnew\r\n";
    is(scalar <$sock>, "STORED\r\n", "stored foo = 'new'");
    mem_get_is($sock, "foo", 'new');
}

sleep 1;
mem_get_is($sock, "foo", undef);

# and the other form, specifying a flush_all time...
my $expire = time() + 2;
print $sock "flush_all $expire\r\n";
is(scalar <$sock>, "OK\r\n", "did flush_all in future");

print $sock "set foo 0 0 4\r\n1234\r\n";
is(scalar <$sock>, "STORED\r\n", "stored foo = '1234'");
mem_get_is($sock, "foo", '1234');
sleep(2.2);
mem_get_is($sock, "foo", undef);
