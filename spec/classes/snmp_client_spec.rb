#!/usr/bin/env rspec

#require 'hiera'
require 'spec_helper'

describe 'snmp::client', :type => 'class' do
  #let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  #hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')

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

  on_supported_os.each do |os, facts|
    context "on #{os}" do

      let(:facts) do
        facts
      end

      let(:params) {{
        :ensure => 'installed',
      }}

      #packages = hiera.lookup('snmp::client::packages', ['snmp-client'], nil)

      #packages.each do |p|
      #  it do
      #    is_expected.to contain_package(p)
      #      .with({
      #        :ensure => 'installed',
      #      })
      #  end
      #end

      it { should contain_file('snmp.conf').with(
          :ensure  => 'file',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
          :path    => '/etc/snmp/snmp.conf',
          #:require => ['Package[snmp-client]', 'File[/etc/snmp]']
      )}
    end
  end

  freebsdish = ['FreeBSD']
  openbsdish = ['OpenBSD']

  freebsdish.each do |os|
    describe "for osfamily FreeBSD, operatingsystem #{os}" do
      let(:params) {{}}
      let :facts do {
        :osfamily               => 'FreeBSD',
        :operatingsystem        => os,
        :operatingsystemrelease => '9.2',
        :operatingsystemmajrelease => '9'
      }
      end
      it { should contain_package('snmp-client').with(
        :ensure => 'installed',
      )}
      it { should_not contain_file('snmp.conf').with(
        :ensure  => 'installed',
        :mode    => '0755',
        :owner   => 'root',
        :group   => 'wheel',
        :path    => '/usr/local/etc/snmp/snmp.conf',
        :require => nil
      )}
    end
  end

  openbsdish.each do |os|
    describe "for osfamily OpenBSD, operatingsystem #{os}" do
      let(:params) {{}}
      let :facts do {
        :osfamily               => 'OpenBSD',
        :operatingsystem        => os,
        :operatingsystemrelease => '5.9',
        :operatingsystemmajrelease => '5'
      }
      end
      it { should contain_package('snmp-client').with(
        :ensure => 'installed',
      )}
      it { should_not contain_file('snmp.conf').with(
        :ensure  => 'installed',
        :mode    => '0755',
        :owner   => 'root',
        :group   => 'wheel',
        :path    => '/etc/snmp/snmp.conf',
        :require => nil
      )}
    end
  end

  context 'on a supported osfamily, custom parameters' do
    let :facts do {
      :osfamily               => 'RedHat',
      :operatingsystem        => 'RedHat',
      :operatingsystemrelease => '6.4',
      :lsbmajdistrelease      => '6',
      :operatingsystemmajrelease => '6'
    }
    end

    describe 'ensure => absent' do
      let(:params) {{ :ensure => 'absent' }}
      it { should contain_package('snmp-client').with_ensure('absent') }
      it { should contain_file('snmp.conf').with_ensure('absent') }
    end

    describe 'autoupgrade => true' do
      let(:params) {{ :autoupgrade => true }}
      it { should contain_package('snmp-client').with_ensure('latest') }
      it { should contain_file('snmp.conf').with_ensure('file') }
    end

    describe 'autoupgrade => false' do
      let(:params) {{ :autoupgrade => false }}
      it { should contain_package('snmp-client').with_ensure('installed') }
      it { should contain_file('snmp.conf').with_ensure('file') }
    end


    describe 'snmp_config => [ "defVersion 2c", "defCommunity public" ]' do
      let(:params) {{ :snmp_config => [ 'defVersion 2c', 'defCommunity public' ] }}
      it { should contain_file('snmp.conf') }
      it 'should contain File[snmp.conf] with contents "defVersion 2c" and "defCommunity public"' do
        verify_contents(catalogue, 'snmp.conf', [
          'defVersion 2c',
          'defCommunity public',
        ])
      end
    end
  end

end
