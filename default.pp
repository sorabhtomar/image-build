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

  Exec {
    path => '/usr/bin',
    cwd  => '/build',
  }
  exec {
    'fetch vagrant':
      command => 'wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb';
    'fetch virtualbox':
      command => 'wget http://download.virtualbox.org/virtualbox/4.3.20/virtualbox-4.3_4.3.20-96996~Ubuntu~raring_amd64.deb',
      before  => Exec['do final apt-get install'];
    'do final apt-get install':
      command => 'apt-get install -f';
  }

  package {
    'librarian':
      provider => 'gem',
      ensure   => present,
      require  => Package['ruby-dev'];
    ['ruby-dev', 'virtualbox']:;
    'virtualbox':
      provider => 'dpkg',
      source   => '/build/virtualbox-4.3_4.3.20-96996~Ubuntu~raring_amd64.deb',
      require  => Exec['fetch virtualbox'];
    'vagrant':
      provider => 'dpkg',
      source   => '/build/vagrant_1.7.2_x86_64.deb',
      require  => Exec['fetch vagrant'];
    # vagrant needed for getting our base image in place, at least for now. this should be
    # abstracted out into a separate system later, probably.
    # the base image can be fetched with this command:
    #
    # vagrant box add udacity/puppet-masterless https://atlas.hashicorp.com/udacity/boxes/puppet-masterless/versions/0.0.1/providers/virtualbox.box
  }
}

class {'leiningen': } -> class {'image_build': }
