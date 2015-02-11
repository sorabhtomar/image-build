class build_dir {
  file {'/build':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }
}

class leiningen {
  include build_dir
  include apt

  package {['git', 'openjdk-7-jdk']:
    require => Class['apt'],
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

class {'leiningen': }
