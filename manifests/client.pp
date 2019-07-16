# == Class: snmp::client
#
# This class handles installing the Net-SNMP client.
#
# === Parameters:
#
# [*conf_file*]
#   Full path to the snmp client configuration file.
#   Default: /etc/snmp.conf
#
# [*snmp_config*]
#   Array of lines to add to the client's global snmp.conf file.
#   See http://www.net-snmp.org/docs/man/snmp.conf.html for all options.
#   Default: []
#
# [*ensure*]
#   Ensure if installed or absent.
#   Default: installed
#
# [*autoupgrade*]
#   Upgrade package automatically, if there is a newer version.
#   Default: false
#
# [*packages*]
#   List of packages.
#
# === Actions:
#
# Installs the Net-SNMP client package and configuration.
#
# === Requires:
#
# Nothing.
#
# === Sample Usage:
#
#   class { 'snmp::client':
#     snmp_config => [ 'defVersion 2c', 'defCommunity public', ],
#   }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
# Michael Watters <wattersm@watters.ws>
#
# === Copyright:
#
# Copyright (C) 2012 Mike Arnold, unless otherwise noted.
#
class snmp::client (
    String $conf_file = '/etc/snmp.conf',
    Array[String] $snmp_config = [],
    Variant[String, Enum['installed', 'present', 'absent']] $ensure = 'installed',
    Boolean $autoupgrade = false,
    Array[String] $packages = ['snmp-client'],
    ) {

    case $ensure {
        /(installed|present)/: {
          if $autoupgrade == true {
              $package_ensure = 'latest'
          }
          else {
              $package_ensure = $ensure
          }

          $file_ensure = 'file'
        }

        /(absent)/: {
            $package_ensure = $ensure
            $file_ensure = $ensure
        }

        default: {
            fail('ensure parameter must be installed or absent')
        }
    }

    package { $packages:
        ensure => $package_ensure,
    }

    if $::osfamily == 'RedHat' {
      file { '/etc/snmp':
        ensure => directory,
        before => File['snmp.conf'],
      }
    }

    $req = $::osfamily ? {
      'Suse'   => undef,
      default  => Package[$packages],
    }

    file { 'snmp.conf':
      ensure    => $file_ensure,
      mode      => '0644',
      owner     => 'root',
      group     => 'root',
      path      => $conf_file,
      content   => template('snmp/snmp.conf.erb'),
      require   => $req,
      show_diff => false,
    }
}
