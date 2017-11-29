# Some standard checks that should be safe on every host
# Plugins must be provided on every supported OS for these!
class nagios::client::checks (
  $nrpe = false,
) {
  # Ping
  nagios::service { 'check_ping':
    service_description => 'Ping',
    plugin_source       => 'nagios-plugins-ping',
    command_definition  => 'check_ping -H $HOSTADDRESS$ -w 100,10% -c 1000,50% -p 5',
  }

  # NRPE
  if ($nrpe) {
    nagios::service { 'check_nrpe_status':
      service_description => 'NRPE',
      plugin_source       => 'nagios-plugins-nrpe',
      command_definition  => 'check_nrpe -H $HOSTADDRESS$',
    }
  }
}
