#!/usr/bin/env rspec

require 'spec_helper'

describe 'snmp::snmpv3_user', :type => 'define' do

  on_supported_os.each do |os, facts|
    context "on #{os}" do

      let(:facts) do
        facts
      end

      context 'authtype => badString' do
        let(:title) { 'authtype' }

        let :params do {
          :authpass => 'myauthpass',
          :authtype => 'badString',
        }
        end

        it 'should fail' do
          expect {
            should raise_error(Puppet::Error, /$authtype must be either SHA or MD5./)
          }
        end
      end

      context 'privtype => badString' do
        let(:title) { 'privtype' }

        let :params do {
          :authpass => 'myauthpass',
          :privtype => 'badString',
        }
        end

        it 'should fail' do
          expect {
            should raise_error(Puppet::Error, /$privtype must be either AES or DES./)
          }
        end
      end

      context 'daemon => badString' do
        let(:title) { 'daemon' }

        let :params do {
          :authpass => 'myauthpass',
          :daemon   => 'badString',
        }
        end

        it 'should fail' do
          expect {
            should raise_error(Puppet::Error, /$daemon must be either snmpd or snmptrapd./)
          }
        end
      end

      context 'with default settings' do
        let(:title) { 'myDEFAULTuser' }

        let :params do {
          :authpass => 'myauthpass',
        }
        end

        it do
          is_expected.to contain_exec('create-snmpv3-user-myDEFAULTuser')
            .with{(
          #:command => 'service snmpd stop ; sleep 5 ; echo "createUser myDEFAULTuser SHA \"myauthpass\"" >>/var/lib/net-snmp/snmpd.conf && touch /var/lib/net-snmp/myDEFAULTuser-snmpd',
          #:creates => '/var/lib/net-snmp/myDEFAULTuser-snmpd',
          #:require => [ 'Package[snmpd]', 'File[var-net-snmp]' ],
            )}
            .that_comes_before('Service[snmpd]')
        end
      end

      context 'with all settings' do
        let(:title) { 'myALLuser' }

        let :params do {
          :authpass => 'myauthpass',
          :authtype => 'MD5',
          :privpass => 'myprivpass',
          :privtype => 'DES'
        }
        end

        it do
          is_expected.to contain_exec('create-snmpv3-user-myALLuser')
            .with{(
            #  :command => 'service snmpd stop ; sleep 5 ; echo "createUser myALLuser MD5 \"myauthpass\" DES \"myprivpass\"" >>/var/lib/net-snmp/snmpd.conf && touch /var/lib/net-snmp/myALLuser-snmpd',
            #  :creates => '/var/lib/net-snmp/myALLuser-snmpd',
            #  :require => [ 'Package[snmpd]', 'File[var-net-snmp]' ],
            )}
            .that_comes_before('Service[snmpd]')
        end
      end

      context 'with snmptrapd settings' do
        let(:title) { 'myTRAPuser' }

        let :params do {
          :authpass => 'myauthpass',
          :daemon   => 'snmptrapd',
        }
        end

        it do
          is_expected.to contain_exec('create-snmpv3-user-myTRAPuser')
            #.with{(
            #  #:command => 'service snmptrapd stop ; sleep 5 ; echo "createUser myTRAPuser SHA \"myauthpass\"" >>/var/lib/net-snmp/snmptrapd.conf && touch /var/lib/net-snmp/myTRAPuser-snmptrapd',
            #  #:creates => '/var/lib/net-snmp/myTRAPuser-snmptrapd',
            #)}
            #.that_requires('Package[snmpd]')
            #.that_requires('File[var-net-snmp]')
            #.that_comes_before('Service[snmptrapd]')
        end
      end
    end
  end
end
