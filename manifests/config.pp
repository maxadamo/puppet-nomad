# This class is called from nomad::init to install the config file.
#
# @api private
class nomad::config {
  if $nomad::manage_service_file {
    systemd::unit_file { 'nomad.service':
      content => template('nomad/nomad.systemd.erb'),
    }
  }

  $_config = $nomad::pretty_config ? {
    true    => stdlib::to_json_pretty($nomad::config_hash_real),
    default => stdlib::to_json($nomad::config_hash_real),
  }

  $validate_cmd = $nomad::config_validator ? {
    'nomad_validator' => 'nomad config validate %',
    'ruby_validator' => '/usr/local/bin/config_validate.rb %',
    default => $nomad::config_validator,
  }

  file { '/usr/local/bin/config_validate.rb':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    before => File['nomad config.json'],
    source => 'puppet:///modules/nomad/config_validate.rb',
  }
  file { $nomad::config_dir:
    ensure  => 'directory',
    owner   => $nomad::user,
    group   => $nomad::group,
    purge   => $nomad::purge_config_dir,
    recurse => $nomad::purge_config_dir,
  }
  -> file { 'nomad config.json':
    ensure       => file,
    owner        => $nomad::user,
    group        => $nomad::group,
    path         => "${nomad::config_dir}/config.json",
    mode         => $nomad::config_mode,
    validate_cmd => $validate_cmd,
    content      => $_config,
  }
  $content = join(map($nomad::env_vars) |$key, $value| { "${key}=${value}" }, "\n")
  file { "${nomad::config_dir}/nomad.env":
    ensure  => 'file',
    owner   => $nomad::user,
    group   => $nomad::group,
    mode    => $nomad::config_mode,
    content => "${content}\n",
    require => File[$nomad::config_dir],
  }
}
