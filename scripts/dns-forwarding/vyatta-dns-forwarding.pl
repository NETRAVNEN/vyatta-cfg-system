#!/usr/bin/perl
#
# Module: vyatta-dns-forwarding.pl
#
# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2008 Vyatta, Inc.
# All Rights Reserved.
#
# Author: Mohit Mehta
# Date: August 2008
# Description: Script to glue Vyatta CLI to dnsmasq daemon
#
# **** End License ****
#

use lib "/opt/vyatta/share/perl5/";
use VyattaConfig;
use VyattaMisc;
use Getopt::Long;

use strict;
use warnings;

my $dnsforwarding_init = '/etc/init.d/dnsmasq';
my $dnsforwarding_conf = '/etc/dnsmasq.conf';

sub dnsforwarding_init {

}

sub dnsforwarding_restart {
    system("$dnsforwarding_init restart >&/dev/null");
    print "Setting up DNS forwarding.\n";
}

sub dnsforwarding_stop {
    system("$dnsforwarding_init stop >&/dev/null");
    print "Stopping DNS forwarding.\n";
}

sub dnsforwarding_get_constants {
    my $output;

    my $date = `date`;
    chomp $date;
    $output  = "#\n# autogenerated by vyatta-dns-forwarding.pl on $date\n#\n";
    return $output;
}

sub dnsforwarding_get_values {
    my $output = '';
    my $config = new VyattaConfig;

    $config->setLevel("service dns forwarding");

    my @ignore_interfaces = $config->returnValues("ignore-interface");
    if ($#ignore_interfaces >= 0) {
       foreach my $interface (@ignore_interfaces) {
          $output .= "except-interface=$interface\n";
       }
    }

    my $cache_size = $config->returnValue("cache-size");
    if (defined $cache_size) {
        $output .= "cache-size=$cache_size\n";
    }

    return $output;
}

sub dnsforwarding_write_file {
    my ($config) = @_;

    open(my $fh, '>', $dnsforwarding_conf) || die "Couldn't open $dnsforwarding_conf - $!";
    print $fh $config;
    close $fh;
}

sub check_nameserver {

    my $cmd = `grep nameserver /etc/resolv.conf|wc -l`;
    return $cmd;
}

#
# main
#
my $init_dnsforwarding;
my $update_dnsforwarding;
my $stop_dnsforwarding;
my $nameserver;

GetOptions("init-dnsforwarding!"   => \$init_dnsforwarding,
           "update-dnsforwarding!" => \$update_dnsforwarding,
           "stop-dnsforwarding!"   => \$stop_dnsforwarding,
           "nameserver!" => \$nameserver);

if (defined $nameserver) {
    my $nameserver_exists = check_nameserver();
    if ($nameserver_exists < 1){
        exit 1;
    } else {
        exit 0;
    }
}


if (defined $init_dnsforwarding) {
    dnsforwarding_init();
}

if (defined $update_dnsforwarding) {
    my $config;

       $config  = dnsforwarding_get_constants();
       $config .= dnsforwarding_get_values();
       dnsforwarding_write_file($config);
       dnsforwarding_restart();
}

if (defined $stop_dnsforwarding) {
    dnsforwarding_stop();
}

exit 0;

# end of file

