# Wrapper for nagios_service to create a service, a servicegroup
# and if necessary, a servicedependency
define nagios::service (
  $check_command,
  $service_description,
  $use = undef,
  $add_servicegroup = true,
  $add_servicedep = true,
  $active_checks_enabled = undef,
  $max_check_attempts    = undef,
  $check_freshness       = undef,
  $freshness_threshold   = undef,
) {
  # Pass on various params to nagios_service
  @@nagios_service { "${title}-${::fqdn}":
    check_command         => $check_command,
    service_description   => $service_description,
    use                   => $use,
    servicegroups         => $title,
    tag                   => hiera('nagios_server'),
    active_checks_enabled => $active_checks_enabled,
    max_check_attempts    => $max_check_attempts,
    check_freshness       => $check_freshness,
    freshness_threshold   => $freshness_threshold,
    target                => "/etc/nagios/conf.d/${::fqdn}-service-${title}.cfg",
  }

  # Also configure a nagios_servicegroup for this service
  @@nagios::servicegroup { "${title}-${::fqdn}":
    groupname  => $title,
    groupalias => $service_description,
    tag        => hiera('nagios_server'),
    target     => "/etc/nagios/conf.d/${::fqdn}-servicegroup-${title}.cfg",
  }

  # Configure a nagios_servicedependency if this is a NRPE check
  if ($check_command =~ /^check_nrpe!/) {
    @@nagios_servicedependency { "${title}_${::fqdn}":
      dependent_host_name           => $::fqdn,
      dependent_service_description => $service_description,
      service_description           => 'NRPE',
      tag                           => hiera('nagios_server'),
      target                        => "/etc/nagios/conf.d/${::fqdn}-servicedependency-${title}.cfg",
    }
  }
}
