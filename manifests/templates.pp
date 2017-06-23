# Standard nagios group templates
class nagios::templates {

  $contacts = concat(hiera_array('contact'), 'slack')

  # Contact templates
  nagios_contact { 'generic-contact':
    service_notification_period   => '24x7',
    host_notification_period      => '24x7',
    service_notification_options  => 'w,c,r,f,s',
    host_notification_options     => 'd,u,r,f,s',
    service_notification_commands => 'notify-service-by-email',
    host_notification_commands    => 'notify-host-by-email',
    register                      => '0',
  }

  # Contactgroup templates
  nagios_contactgroup { 'admins':
    alias => 'Nagios Administrators',
  }
  nagios_contactgroup { 'users':
    alias => 'Nagios Users',
  }

  # Host templates
  nagios_host { 'generic-host':
    notifications_enabled        => '1',
    event_handler_enabled        => '1',
    flap_detection_enabled       => '1',
    process_perf_data            => '1',
    retain_status_information    => '1',
    retain_nonstatus_information => '1',
    notification_period          => '24x7',
    register                     => '0',
    check_period                 => '24x7',
    check_interval               => '5',
    retry_interval               => '2',
    max_check_attempts           => '2',
    check_command                => 'check-host-alive',
    notification_interval        => '0',
    notification_options         => 'd,r',
    contacts                     => inline_template("<%= @contacts.join(',') %>"),
  }

  nagios_host { 'agregate-host':
    use             => 'generic-host',
    check_command   => 'check_dummy!0',
    register        => '0',
    icon_image      => 'aggregate.png',
    statusmap_image => 'aggregate.gd2',
  }

  # Service templates
  nagios_service{ 'generic-service':
    active_checks_enabled        => '1',
    passive_checks_enabled       => '1',
    parallelize_check            => '1',
    obsess_over_service          => '1',
    check_freshness              => '0',
    notifications_enabled        => '1',
    event_handler_enabled        => '1',
    flap_detection_enabled       => '1',
    process_perf_data            => '1',
    retain_status_information    => '1',
    retain_nonstatus_information => '1',
    is_volatile                  => '0',
    check_period                 => '24x7',
    max_check_attempts           => '3',
    normal_check_interval        => '1',
    retry_check_interval         => '1',
    notification_options         => 'w,c,r',
    notification_interval        => '0',
    notification_period          => '24x7',
    register                     => '0',
    }

  nagios_service { 'hourly-service':
    use                   => 'generic-service',
    register              => '0',
    normal_check_interval => '60',
  }

  nagios_service { 'daily-service':
    use                   => 'generic-service',
    register              => '0',
    normal_check_interval => '1440',
  }
}
