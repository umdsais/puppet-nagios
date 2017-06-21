# Generate a config item for BPI

# define [groupID] - groupID must be alphanumeric characters with no spaces. This id is used internally by the program as well as for the check_bpi.php plugin
# displayname - the display name for the bpi group (value is required)
# desc - a description for a bpi group (value is optional)
# primary - boolean (1 or 0), Primary/Top-Level groups are primary=1, subgroups are primary=0
# info - link to internal or external webpage (value is optional)
# members - a comma delineated list of members.
#    For services, format is: <hostname>;<servicename>;<opt>,
#    For groups, format is:  $<groupID>;<opt>,   (DO NOT USE SPACES FOR THE groupID!!!)
#        the <opt> is an '&' or '|' character.
#        '&' option after host:servicename means service is part of a CLUSTER
#    For clusters, 'critical' is only reached when ALL services in a cluster are NOT 'Ok'
#       '|' option after host:servicename means it is an essential service for the group,
#       example: a 'critical' service with an '|' option will cause a 'critical' state
#       for the entire group.
#
# warning_threshold - the number of problems a group reaches before going 'warning'
# critical_threshold - the number of problems a group reaches before going 'critical'
# priority - (1-3) this sets the display priority on screen, 1 being 'high priority'

define nagios::bpi::config (
  $displayname,
  $members,
  $nagios = true,
  $desc = undef,
  $primary = 1,
  $info = undef,
  $warning_threshold = 0,
  $critical_threshold = 0,
  $priority = 1,
  $event_handler = undef,
) {
  concat::fragment{ "bpi-${title}":
    target  => 'bpi.conf',
    content => template('nagios/bpi.conf.erb'),
    order   => '20',
  }

  if $nagios == true {
    nagios_service { "check_bpi_${title}":
      host_name           => 'bpi',
      check_command       => "check_bpi!${title}",
      service_description => $displayname,
      event_handler       => $event_handler,
    }
  }
}
