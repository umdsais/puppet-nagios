# Wrapper for nagios_service to create a service, a servicegroup
# and if necessary, a servicedependency
define nagios::service (
  $host_name = $::fqdn,
  $check_command = $title,
  $service_description,
  $use = undef,
  $servicegroups = $title,
  $add_servicegroup = true,
  $add_servicedep = true,
  $active_checks_enabled = undef,
  $max_check_attempts    = undef,
  $check_freshness       = undef,
  $freshness_threshold   = undef,
  $command_definition = $check_command,
  $check_interval = undef,
  $use_nrpe = false,
  $use_sudo = false,
  $sudo_user = undef,
  $install_plugin = true,
  $plugin_provider = 'package',
  $plugin_source = undef,
  $service_dependency = undef,
  $nagios_server = hiera('nagios_server'),
) {
  # Pass on various params to nagios_service
  @@nagios_service { "${title}-${host_name}":
    host_name             => $host_name,
    check_command         => $use_nrpe ? {
      true    => "check_nrpe!${check_command}",
      default => $check_command,
    },
    service_description   => $service_description,
    use                   => $use,
    servicegroups         => $servicegroups,
    tag                   => $nagios_server,
    active_checks_enabled => $active_checks_enabled,
    max_check_attempts    => $max_check_attempts,
    check_freshness       => $check_freshness,
    normal_check_interval => $check_interval,
    freshness_threshold   => $freshness_threshold,
    target                => "/etc/nagios/conf.d/${host_name}-service-${title}.cfg",
  }

  if ($add_servicegroup) {
    # Also configure a nagios_servicegroup for this service
    @@nagios::servicegroup { "${title}-${host_name}":
      groupname  => $title,
      groupalias => $service_description,
      tag        => $nagios_server,
    }
  }

  if ($service_dependency) {
    # Configure a nagios_servicedependency on arbitrary other services on this host
    @@nagios_servicedependency { "${title}_${host_name}_${service_dependency}":
      dependent_host_name           => $host_name,
      dependent_service_description => $service_description,
      service_description           => $service_dependency,
      tag                           => $nagios_server,
      target                        => "/etc/nagios/conf.d/${host_name}-servicedependency-${title}-${service_dependency}.cfg",
    }
  }

  if ($use_nrpe) {
    # Configure a nagios_servicedependency on NRPE if this is a NRPE check
    @@nagios_servicedependency { "${title}_${host_name}_NRPE":
      dependent_host_name           => $host_name,
      dependent_service_description => $service_description,
      service_description           => 'NRPE',
      tag                           => $nagios_server,
      target                        => "/etc/nagios/conf.d/${host_name}-servicedependency-${title}-NRPE.cfg",
    }

    # Install plugin on client
    if ($install_plugin) {
      nagios::plugin { "${title}-${host_name}":
        plugin_provider => $plugin_provider,
        plugin_source   => $plugin_source,
      }
    }

    # Configure nrpeconfig
    nagios::nrpe::config { $title:
      command   => $command_definition,
      sudo      => $use_sudo,
      sudo_user => $sudo_user,
    }
  } else {
    if ($install_plugin) {
      # Install plugin on server
      @@nagios::plugin { "${title}-${host_name}":
        plugin_provider => $plugin_provider,
        plugin_source   => $plugin_source,
        tag             => $nagios_server,
      }

      # Configure plugin on server
      @@nagios::command { "${title}-${host_name}":
        command_name => $title,
        command_line => "\$USER1\$/${command_definition}",
        tag          => $nagios_server,
      }
    }
  }
}
