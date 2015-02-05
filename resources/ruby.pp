class common {
  include '::ntp'
  $service_name = 'grading-api'

  Exec {
    path => ['/bin', '/usr/bin', '/usr/local/bin'],
  }

  Package {
    require => Exec['apt-get-update'],
  }

  user {
    $service_name:
      ensure     => present,
      managehome => true,
      shell      => '/usr/sbin/nologin';
    'riemann':
      ensure     => present,
      shell      => '/usr/sbin/nologin';
  }

  group {
    $service_name:
      members => [$service_name],
      require => User[$service_name],
  }

  package {
    'ruby-dev':
      ensure  => '1:1.9.3.4';
    'build-essential':
      ensure  => '11.6ubuntu6';
    'zlib1g-dev':
      ensure  => '1:1.2.8.dfsg-1ubuntu1';
    'riemann-tools':
      ensure   => '0.2.0',
      provider => 'gem',
      require  => [Package['ruby-dev'], Package['build-essential'], Package['zlib1g-dev']];
  }

  class upstart_files ($service_name = 'rumours') {
    File {
      require => Exec["untar-${service_name}"],
      owner   => 'root',
      group   => 'root',
    }

    file {
      '/etc/init/ejabberd.conf':
        source  => "/home/${service_name}/upstart/ejabberd.conf";
      '/etc/init/riemann-proc.conf':
        source => "/home/${service_name}/upstart/riemann-proc.conf";
      '/etc/init/riemann-health.conf':
        source => "/home/${service_name}/upstart/riemann-health.conf";
      '/etc/init/riemann-fd.conf':
        source => "/home/${service_name}/upstart/riemann-fd.conf";
    }
  }

  class {
    'upstart_files':
      service_name => $service_name;
  }

  exec {
    'apt-get-update':
      command  => 'apt-get update';
    "untar-${service_name}":
      command  => "tar -xvf /tmp/${service_name}.tar",
      user     => $service_name,
      cwd      => "/home/${service_name}",
      require  => User[$service_name];
    'set_hostname':
      command => "hostname ${service_name}";
  }
}

class rails {
  # package {
  #   'gpg2':
  #     ensure => 'present',
  #     before => [Class['rvm'], Rvm_system_ruby['ruby-2.1']];
  # }

  include rvm
  rvm_system_ruby {
    'ruby-2.1':
      ensure      => 'present',
      default_use => false;
  }

  rvm::system_user {
    'ubuntu':;
    'vagrant':;
  }

  Exec {
    path => ['/bin', '/usr/bin', '/usr/local/bin', '/usr/local/rvm/bin'],
  }

  exec {
    'install bundler':
      command => 'rvm ruby-2.1 do gem install bundler';
    'install dependencies':
      command => 'rvm ruby-2.1 do bundle install',
      cwd     => '/home/app',
      require => Rvm_system_ruby['ruby-2.1'],
  }
}

class {'common':} -> class {'rails':}
