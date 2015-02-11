class build_dir {
  file {'/build':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }
}

class leiningen {
  include build_dir

  exec {'apt-update':
    command => "/usr/bin/apt-get update -qy",
  }

  package {['git', 'openjdk-7-jdk']:
    require => Exec['apt-update'],
  }

  vcsrepo {'/build/leiningen':
    source => 'https://github.com/technomancy/leiningen.git',
    provider => 'git',
    revision => '2.5.1',
    require  => Package['git', 'openjdk-7-jdk'],
  }

  file {'/usr/local/bin/lein':
    source => '/build/leiningen/bin/lein',
    owner  => 'root',
    group  => 'root',
    mode   => 'a=rx,u=w',
    require => Vcsrepo['/build/leiningen'],
  }
}

class image_build {
  class {'packer': }

  package {
    'librarian-puppet':
      provider => 'gem',
      ensure   => present,
      require  => Package['ruby-dev', 'build-essential'];
    ['ruby-dev', 'build-essential']:;
  }
}

class {'leiningen': } -> class {'image_build': }
