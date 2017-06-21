# Install a nrpe config snippet to make the plugin accessible
# Some stock plugins lack a NRPE snippet so will need nrpeconfig{}
# without nagiosplugin{}
define nagios::nrpe::config(
  $command,
  $sudo = undef,
  $sudo_user = 'root',
  $ensure = present,
) {

  if ! ($ensure in [ 'present', 'absent' ]) {
    fail('nagios::nrpe::config ensure parameter must be absent or present')
  }

  file { "${title}.cfg":
    ensure  => $ensure,
    name    => $::osfamily ? {
      'RedHat' => "/etc/nrpe.d/${title}.cfg",
      'Debian' => "/etc/nagios/nrpe.d/${title}.cfg",
      default  => "/etc/nrpe.d/${title}.cfg",
    },
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

    logwatch::ignore { $title:
      regex => "/usr/${::lib_path}/nagios/plugins/${array[0]}",
    }
  }
}
