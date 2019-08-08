#!/usr/bin/env rspec

require 'spec_helper'

describe 'snmp', :type => 'class' do

  test_on = {
    :hardwaremodels => 'x86_64',
    :supported_os   => [
      {
        'operatingsystem'        => 'CentOS',
        'operatingsystemrelease' => ['7'],
      },
    ],
  }

  context 'on a non-supported osfamily' do
    let(:params) {{}}
    let :facts do {
      :osfamily        => 'foo',
      :operatingsystem => 'bar'
    }
    end
    it 'should fail' do
      expect {
        should raise_error(Puppet::Error, /Module snmp is not supported on bar/)
      }
    end
  end

  on_supported_os().each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      let(:params) {{
        :ensure => 'present',
      }}

      it do
        is_expected.to contain_package('net-snmp')
            .with({
              :ensure => 'installed',
            })
      end

      it { should_not contain_class('snmp::client') }

      it do
        is_expected.to contain_file('var-net-snmp')
        .with({
          :ensure  => 'directory',
          :mode    => '0755',
          :owner   => 'root',
          :group   => 'root',
          :path    => '/var/lib/net-snmp',
        })
        .that_requires('Package[net-snmp]')
      end

      it do
        is_expected.to contain_file('snmpd.conf')
        .with({
          :ensure  => 'file',
          :mode    => '0600',
          :owner   => 'root',
          :group   => 'root',
          :path    => '/etc/snmp/snmpd.conf',
        })
        .that_requires('Package[net-snmp]')
        .that_notifies('Service[snmpd]')
      end

      it do
        is_expected.to contain_file('snmpd.sysconfig')
            .with({
              :ensure  => 'file',
              :mode    => '0644',
              :owner   => 'root',
              :group   => 'root',
              :path    => '/etc/sysconfig/snmpd',
            })
            .that_requires('Package[net-snmp]')
            .that_notifies('Service[snmpd]')
      end

      it { is_expected.to contain_service('snmpd')
        .with({
          :ensure     => 'running',
          :name       => 'snmpd',
          :enable     => true,
          :hasstatus  => true,
          :hasrestart => true,
        })
        .that_requires('Package[net-snmp]')
      }

      it { is_expected.to contain_file('snmptrapd.conf')
        .with({
          :ensure  => 'file',
          :mode    => '0600',
          :owner   => 'root',
          :group   => 'root',
          :path    => '/etc/snmp/snmptrapd.conf',
        })
        .that_requires('Package[net-snmp]')
        .that_notifies('Service[snmptrapd]')
      }

      it { is_expected.to contain_file('snmptrapd.sysconfig')
        .with({
          :ensure  => 'file',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
          :path    => '/etc/sysconfig/snmptrapd',
        })
        .that_requires('Package[net-snmp]')
        .that_notifies('Service[snmptrapd]')
      }

      it { is_expected.to contain_service('snmptrapd').with({
        :ensure     => 'stopped',
        :name       => 'snmptrapd',
        :enable     => false,
        :hasstatus  => true,
        :hasrestart => true,
        })
        .that_requires('Package[net-snmp]')
      }

      context 'on a supported osfamily (RedHat), custom parameters' do |facts|
        describe 'ensure => absent, service_ensure => stopped' do
          let(:params) {{ :ensure => 'absent', :service_ensure => 'stopped' }}
          it { should contain_package('net-snmp').with_ensure('absent') }
          it { should_not contain_class('snmp::client') }
          it { should contain_file('var-net-snmp').with_ensure('directory') }
          it { should contain_file('snmpd.conf').with_ensure('absent') }
          it { should contain_file('snmpd.sysconfig').with_ensure('absent') }
          it { should contain_service('snmpd').with_ensure('stopped') }
          it { should contain_file('snmptrapd.conf').with_ensure('absent') }
          it { should contain_file('snmptrapd.sysconfig').with_ensure('absent') }
          it { should contain_service('snmptrapd').with_ensure('stopped') }
        end

        describe 'ensure => badvalue' do
          let(:params) {{ :ensure => 'badvalue' }}
          it 'should fail' do
            expect {
              should raise_error(Puppet::Error, /ensure parameter must be installed or absent/)
            }
          end
        end

        describe 'autoupgrade => true' do
          let(:params) {{ :autoupgrade => true }}
          it { should contain_package('net-snmp').with_ensure('latest') }
          it { should_not contain_class('snmp::client') }
          it { should contain_file('var-net-snmp').with_ensure('directory') }
          it { should contain_file('snmpd.conf').with_ensure('file') }
          it { should contain_file('snmpd.sysconfig').with_ensure('file') }
          it { should contain_service('snmpd').with_ensure('running') }
          it { should contain_file('snmptrapd.conf').with_ensure('file') }
          it { should contain_file('snmptrapd.sysconfig').with_ensure('file') }
          it { should contain_service('snmptrapd').with_ensure('stopped') }
        end

        describe 'autoupgrade => badvalue' do
          let(:params) {{ :autoupgrade => 'badvalue' }}
          it 'should fail' do
            expect {
              should raise_error(Puppet::Error, /"badvalue" is not a boolean./)
            }
          end
        end

        describe 'service_ensure => badvalue' do
          let(:params) {{ :service_ensure => 'badvalue' }}
          it 'should fail' do
            expect {
              should raise_error(Puppet::Error, /service_ensure parameter must be running or stopped/)
            }
          end
        end

        describe 'service_config_perms => "0123"' do
          let(:params) {{ :service_config_perms => '0123' }}
          it { should contain_file('snmpd.conf').with_mode('0123') }
          it { should contain_file('snmptrapd.conf').with_mode('0123') }
        end

        describe 'service_config_dir_group => "anothergroup"' do
          let(:params) {{ :service_config_dir_group => 'anothergroup' }}
          it { should contain_file('snmpd.conf').with_group('anothergroup') }
          it { should contain_file('snmptrapd.conf').with_group('anothergroup') }
        end

        describe 'manage_client => true' do
          let(:params) {{ :manage_client => true }}
          it { should contain_class('snmp::client').with(
            :ensure        => 'present',
            :autoupgrade   => 'false',
          )}
        end

        describe 'manage_client => true' do
          let(:params) {{ :manage_client => true }}
          it { should contain_class('snmp::client').with(
            :ensure      => 'present',
            :autoupgrade => 'false',
          )}
        end

        describe 'manage_client => true, ensure => absent, and autoupgrade => true' do
          let :params do {
            :manage_client => true,
            :ensure        => 'absent',
            :autoupgrade   => true,
          }
          end
          it { should contain_class('snmp::client').with(
            :ensure      => 'absent',
            :autoupgrade => 'true',
          )}
        end

        describe 'service_ensure => stopped' do
          let(:params) {{ :service_ensure => 'stopped' }}
          it { should contain_service('snmpd').with_ensure('stopped') }
          it { should contain_service('snmptrapd').with_ensure('stopped') }
        end

        describe 'trap_service_ensure => running' do
          let(:params) {{ :trap_service_ensure => 'running' }}
          it { should contain_service('snmpd').with_ensure('running') }
          it { should contain_service('snmptrapd').with_ensure('running') }
        end

        describe 'service_ensure => stopped and trap_service_ensure => running' do
          let :params do {
            :service_ensure      => 'stopped',
            :trap_service_ensure => 'running'
          }
          end
          it { should contain_service('snmpd').with_ensure('stopped') }
          it { should contain_service('snmptrapd').with_ensure('running') }
        end

        #describe 'snmpd_options => blah' do
        #  let(:params) {{ :snmpd_options => 'blah' }}
        #  it { should contain_file('snmpd.sysconfig') }
        #  it 'should contain File[snmpd.sysconfig] with contents "OPTIONS=\'blah\'"' do
        #    verify_contents(catalogue, 'snmpd.sysconfig', [
        #      'OPTIONS="blah"',
        #    ])
        #  end
        #end

        #describe 'snmptrapd_options => bleh' do
        #  let(:params) {{ :snmptrapd_options => 'bleh' }}
        #  it { should contain_file('snmptrapd.sysconfig') }
        #  it 'should contain File[snmptrapd.sysconfig] with contents "OPTIONS=\'bleh\'"' do
        #    verify_contents(catalogue, 'snmptrapd.sysconfig', [
        #      'OPTIONS="bleh"',
        #    ])
        #  end
        #end

        #describe 'com2sec => [ SomeString ]' do
        #  let(:params) {{ :com2sec => [ 'SomeString', ] }}
        #  it 'should contain File[snmpd.conf] with contents "com2sec SomeString"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'com2sec SomeString',
        #    ])
        #  end
        #end

        #describe 'com2sec6 => [ SomeString ]' do
        #  let(:params) {{ :com2sec6 => [ 'SomeString', ] }}
        #  it 'should contain File[snmpd.conf] with contents "com2sec6 SomeString"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'com2sec6 SomeString',
        #    ])
        #  end
        #end

        #describe 'groups => [ SomeString ]' do
        #  let(:params) {{ :groups => [ 'SomeString', ] }}
        #  it 'should contain File[snmpd.conf] with contents "group SomeString"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'group   SomeString',
        #    ])
        #  end
        #end

        #describe 'views => [ "SomeArray1", "SomeArray2" ]' do
        #  let(:params) {{ :views => [ 'SomeArray1', 'SomeArray2' ] }}
        #  it 'should contain File[snmpd.conf] with contents from array' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'view    SomeArray1',
        #      'view    SomeArray2',
        #    ])
        #  end
        #end

        #describe 'accesses => [ "SomeArray1", "SomeArray2" ]' do
        #  let(:params) {{ :accesses => [ 'SomeArray1', 'SomeArray2' ] }}
        #  it 'should contain File[snmpd.conf] with contents from array' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'access  SomeArray1',
        #      'access  SomeArray2',
        #    ])
        #  end
        #end

        #describe 'dlmod => [ SomeString ]' do
        #  let(:params) {{ :dlmod => [ 'SomeString', ] }}
        #  it 'should contain File[snmpd.conf] with contents "dlmod SomeString"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'dlmod SomeString',
        #    ])
        #  end
        #end

        #describe 'openmanage_enable => true' do
        #    let(:params) {{ :openmanage_enable => true }}
        #    it 'should contain File[snmpd.conf] with contents "smuxpeer .1.3.6.1.4.1.674.10892.1"' do
        #        verify_contents(catalogue, 'snmpd.conf', [
        #            'smuxpeer .1.3.6.1.4.1.674.10892.1',
        #        ])
        #    end
        #    it 'should contain File[snmpd.conf] with contents "smuxpeer .1.3.6.1.4.1.674.10893.1"' do
        #        verify_contents(catalogue, 'snmpd.conf', [
        #            'smuxpeer .1.3.6.1.4.1.674.10893.1',
        #        ])
        #    end
        #end

        #describe 'agentaddress => [ "1.2.3.4", "8.6.7.5:222" ]' do
        #  let(:params) {{ :agentaddress => ['1.2.3.4','8.6.7.5:222'] }}
        #  it 'should contain File[snmpd.conf] with contents "agentaddress 1.2.3.4,8.6.7.5:222"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'agentaddress 1.2.3.4,8.6.7.5:222',
        #    ])
        #  end
        #end

        #describe 'do_not_log_tcpwrappers => "yes"' do
        #    let(:params) {{:do_not_log_tcpwrappers => 'yes'}}
        #    it 'should contain File[snmpd.conf] with contents "dontLogTCPWrappersConnects yes' do
        #        verify_contents(catalogue, 'snmpd.conf', [
        #            'dontLogTCPWrappersConnects yes',
        #        ])
        #    end
        #end

        #describe 'snmptrapdaddr => [ "5.6.7.8", "2.3.4.5:3333" ]' do
        #  let(:params) {{ :snmptrapdaddr => ['5.6.7.8','2.3.4.5:3333'] }}
        #  it 'should contain File[snmptrapd.conf] with contents "snmpTrapdAddr 5.6.7.8,2.3.4.5:3333"' do
        #    verify_contents(catalogue, 'snmptrapd.conf', [
        #      'snmpTrapdAddr 5.6.7.8,2.3.4.5:3333',
        #    ])
        #  end
        #end

        #describe 'snmpd_config => [ "option 1", "option 2", ]' do
        #  let(:params) {{ :snmpd_config => [ 'option 1', 'option 2', ] }}
        #  it 'should contain File[snmpd.conf] with contents "option1" and "option 2"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'option 1',
        #      'option 2',
        #    ])
        #  end
        #end

        #describe 'snmptrapd_config => [ "option 3", "option 4", ]' do
        #  let(:params) {{ :snmptrapd_config => [ 'option 3', 'option 4', ] }}
        #  it 'should contain File[snmptrapd.conf] with contents "option 3" and "option 4"' do
        #    verify_contents(catalogue, 'snmptrapd.conf', [
        #      'option 3',
        #      'option 4',
        #    ])
        #  end
        #end

        #describe 'ro_network => [ "127.0.0.1 192.168.1.1/24", ]' do
        #  let(:params) {{ :ro_network => '127.0.0.1 192.168.1.1/24' }}
        #  it 'should contain File[snmpd.conf] with contents "127.0.0.1" and "192.168.1.1/24"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'rocommunity public 127.0.0.1',
        #      'rocommunity public 192.168.1.1/24',
        #    ])
        #  end
        #end

        #describe 'ro_network => "127.0.0.2"' do
        #  let(:params) {{ :ro_network => '127.0.0.2' }}
        #  it 'should contain File[snmpd.conf] with contents "127.0.0.2"' do
        #    verify_contents(catalogue, 'snmpd.conf', [
        #      'rocommunity public 127.0.0.2',
        #    ])
        #  end
        #end

        describe 'ro_community => "a b" and ro_network => "127.0.0.2"' do
          let(:params) {{ :ro_community => 'a b', :ro_network => '127.0.0.2' }}

          #it 'should contain File[snmpd.conf] with contents "a 127.0.0.2" and "b 127.0.0.2"' do
          #  verify_contents(catalogue, 'snmpd.conf', [
          #    'rocommunity a 127.0.0.2',
          #    'rocommunity b 127.0.0.2',
          #  ])
          #end

          #it 'should contain File[snmptrapd.conf] with contents "a" and "b"' do
          #  verify_contents(catalogue, 'snmptrapd.conf', [
          #    'authCommunity log,execute,net a',
          #    'authCommunity log,execute,net b',
          #  ])
          #end
        end
      end

      #context 'on a supported osfamily (Debian), custom parameters' do
      #  let :facts do {
      #    :osfamily               => 'Debian',
      #    :operatingsystem        => 'Debian',
      #    :operatingsystemrelease => '7.0',
      #    :lsbmajdistrelease      => '7',
      #    :operatingsystemmajrelease => '7'
      #  }
      #  end

      #  describe 'service_ensure => stopped and trap_service_ensure => running' do
      #    let :params do {
      #      :service_ensure      => 'stopped',
      #      :trap_service_ensure => 'running'
      #    }
      #    end
      #    it { should contain_service('snmpd').with_ensure('stopped') }
      #    it { should_not contain_service('snmptrapd') }
      #    #it 'should contain File[snmpd.sysconfig] with contents "SNMPDRUN=no" and "TRAPDRUN=yes"' do
      #    #  verify_contents(catalogue, 'snmpd.sysconfig', [
      #    #    'SNMPDRUN=no',
      #    #    'TRAPDRUN=yes',
      #    #  ])
      #    #end
      #  end

      #  describe 'snmpd_options => blah' do
      #    let(:params) {{ :snmpd_options => 'blah' }}
      #    it { should contain_file('snmpd.sysconfig') }
      #    #it 'should contain File[snmpd.sysconfig] with contents "SNMPDOPTS=\'blah\'"' do
      #    #  verify_contents(catalogue, 'snmpd.sysconfig', [
      #    #    'SNMPDOPTS=\'blah\'',
      #    #  ])
      #    end
      #  end

      #  describe 'snmptrapd_options => bleh' do
      #    let(:params) {{ :snmptrapd_options => 'bleh' }}
      #    it { should contain_file('snmpd.sysconfig') }
      #    #it 'should contain File[snmpd.sysconfig] with contents "TRAPDOPTS=\'bleh\'"' do
      #    #  verify_contents(catalogue, 'snmpd.sysconfig', [
      #    #    'TRAPDOPTS=\'bleh\'',
      #    #  ])
      #    #end
      #  end
      #end

      #context 'on a supported osfamily (Debian Stretch), custom parameters' do
      #  let :facts do {
      #    :osfamily               => 'Debian',
      #    :operatingsystem        => 'Debian',
      #    :lsbmajdistrelease      => '9',
      #    :operatingsystemmajrelease => '9'
      #  }
      #  end

      #  describe 'service_ensure => stopped and trap_service_ensure => running' do
      #    let :params do {
      #      :service_ensure      => 'stopped',
      #      :trap_service_ensure => 'running'
      #    }
      #    end
      #  end

      #  describe 'Debian-snmp as snmp user' do
      #    it 'should contain File[snmpd.sysconfig] with contents "OPTIONS="-Lsd -Lf /dev/null -u Debian-snmp -g Debian-snmp -I -smux -p /var/run/snmpd.pid""' do
      #      #verify_contents(catalogue, 'snmpd.sysconfig', [
      #      #  'SNMPDOPTS=\'-Lsd -Lf /dev/null -u Debian-snmp -g Debian-snmp -I -smux -p /var/run/snmpd.pid\'', 
      #      #])
      #    end
      #  end
      #end

      #context 'on a supported osfamily (Suse), custom parameters' do
      #  let :facts do {
      #    :osfamily               => 'Suse',
      #    :operatingsystem        => 'Suse',
      #    :operatingsystemrelease => '11.1',
      #    :lsbmajdistrelease      => '11',
      #    :operatingsystemmajrelease => '11'
      #  }
      #  end

      #  describe 'service_ensure => stopped' do
      #    let(:params) {{ :service_ensure => 'stopped' }}
      #    it { should contain_service('snmpd').with_ensure('stopped') }
      #    it { should contain_service('snmptrapd').with_ensure('stopped') }
      #  end

      #  describe 'trap_service_ensure => running' do
      #    let(:params) {{ :trap_service_ensure => 'running' }}
      #    it { should contain_service('snmpd').with_ensure('running') }
      #    it { should contain_service('snmptrapd').with_ensure('running') }
      #  end

      #  describe 'service_ensure => stopped and trap_service_ensure => running' do
      #    let :params do {
      #      :service_ensure      => 'stopped',
      #      :trap_service_ensure => 'running'
      #    }
      #    end
      #    it { should contain_service('snmpd').with_ensure('stopped') }
      #    it { should contain_service('snmptrapd').with_ensure('running') }
      #  end

      #  describe 'snmpd_options => blah' do
      #    let(:params) {{ :snmpd_options => 'blah' }}
      #    it { should contain_file('snmpd.sysconfig') }
      #    it 'should contain File[snmpd.sysconfig] with contents "SNMPD_LOGLEVEL="blah""' do
      #      verify_contents(catalogue, 'snmpd.sysconfig', [
      #        'SNMPD_LOGLEVEL="blah"',
      #      ])
      #    end
      #  end
      #end
    end
  end
end
