# Install a nrpe config snippet to make the plugin accessible
# Some stock plugins lack a NRPE snippet so will need nrpeconfig{}
# without nagiosplugin{}
define nagios::nrpe::config(
  String $command,
  String $sudo = undef,
  String $sudo_user = 'root',
  String $ensure = present,
  String $nrpe_d = $::nagios::params::nrpe_d,
) {

  if ! ($ensure in [ 'present', 'absent' ]) {
    fail('nagios::nrpe::config ensure parameter must be absent or present')
  }

  file { "${title}.cfg":
    ensure  => $ensure,
    name    => "${nrpe_d}/${title}.cfg",
    content => $sudo ? {
      true    => "command[${title}]=/usr/bin/sudo -u ${sudo_user} /usr/${::lib_path}/nagios/plugins/${command}\n",
      default => "command[${title}]=/usr/${::lib_path}/nagios/plugins/${command}\n",
    },
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nrpe'],
    notify  => Service['nrpe'],
  }

  # Omit this sudo from Logwatch
  if $sudo == true {

    # Split command from its args
    $array = split($command, ' ')
    $shortcmd = $array[0]

    # Create sudo rule
    sudo::conf { $title:
      priority => 10,
      content  => "nrpe ALL=(ALL) NOPASSWD: /usr/${::lib_path}/nagios/plugins/${shortcmd}",
    }

    # Omit this sudo rule from the logwatch to avoid clutter
    logwatch::ignore { $title:
      regex => "/usr/${::lib_path}/nagios/plugins/${shortcmd}",
    }
  }
}
