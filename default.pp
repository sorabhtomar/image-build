class build_dir {
  file {'/build':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
  }
}

class leiningen {
  include build_dir

  vcsrepo {'/build/leiningen':
    source => 'git@github.com:technomancy/leiningen.git',
    provider => 'git',
    revision => '2.5.1',
  }

  file {'/usr/local/bin/lein':
    source => '/build/leiningen/bin/lein',
    owner  => 'root',
    group  => 'root',
    mode   => 'ugo+rx, u+w',
    require => Vcsrepo['/build/leiningen'],
  }
}

class {'leiningen': }
