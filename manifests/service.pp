# Wrapper for nagios_service to create a service, a servicegroup
# and if necessary, a servicedependency
define nagios::service (
  $host_name = $::fqdn,
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
  @@nagios_service { "${title}-${host_name}":
    host_name             => $host_name,
    check_command         => $check_command,
    service_description   => $service_description,
    use                   => $use,
    servicegroups         => $title,
    tag                   => hiera('nagios_server'),
    active_checks_enabled => $active_checks_enabled,
    max_check_attempts    => $max_check_attempts,
    check_freshness       => $check_freshness,
    freshness_threshold   => $freshness_threshold,
    target                => "/etc/nagios/conf.d/${host_name}-service-${title}.cfg",
  }

  # Also configure a nagios_servicegroup for this service
  @@nagios::servicegroup { "${title}-${host_name}":
    groupname  => $title,
    groupalias => $service_description,
    tag        => hiera('nagios_server'),
    target     => "/etc/nagios/conf.d/${host_name}-servicegroup-${title}.cfg",
  }

  # Configure a nagios_servicedependency if this is a NRPE check
  if ($check_command =~ /^check_nrpe!/) {
    @@nagios_servicedependency { "${title}_${host_name}":
      dependent_host_name           => $host_name,
      dependent_service_description => $service_description,
      service_description           => 'NRPE',
      tag                           => hiera('nagios_server'),
      target                        => "/etc/nagios/conf.d/${host_name}-servicedependency-${title}.cfg",
    }
  }
}
