# Standard nagios group templates
class nagios::templates {

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
    contact_groups               => 'users',
  }

  nagios_host { 'agregate-host':
    use             => 'generic-host',
    check_command   => 'check_dummy!0',
    register        => '0',
    icon_image      => 'aggregate.png',
    statusmap_image => 'aggregate.gd2',
  }

  # Command required for the above
  nagios_command { 'check-host-alive':
    command_line => '$USER1$/check_ping -H $HOSTADDRESS$ -w 1000.0,20% -c 3000.0,90% -p 1',
  }

  nagios_command { 'notify-host-by-email':
    command_line => '/usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\nHost: $HOSTNAME$\nState: $HOSTSTATE$\nAddress: $HOSTADDRESS$\nInfo: $HOSTOUTPUT$\n\nDate/Time: $LONGDATETIME$\n" | /bin/mail -s "** $NOTIFICATIONTYPE$ Host Alert: $HOSTNAME$ is $HOSTSTATE$ **" $CONTACTEMAIL$',
  }

  nagios_command { 'notify-service-by-email':
    command_line => '/usr/bin/printf "%b" "***** Nagios *****\n\nNotification Type: $NOTIFICATIONTYPE$\n\nService: $SERVICEDESC$\nHost: $HOSTALIAS$\nAddress: $HOSTADDRESS$\nState: $SERVICESTATE$\n\nDate/Time: $LONGDATETIME$\n\nAdditional Info:\n\n$SERVICEOUTPUT$" | /bin/mail -s "** $NOTIFICATIONTYPE$ Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **" $CONTACTEMAIL$',
  }

  nagios_command { 'check_dummy':
    command_line => '$USER1$/check_dummy $ARG1$',
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
    normal_check_interval        => '2',
    retry_check_interval         => '1',
    notification_options         => 'w,c,u,r',
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
