# Create Nagios users
define nagios::user (
  $alias=undef,
  $email=undef,
  $use = 'generic-contact',
  $ensure=present,
  $contactgroups = undef,
) {
  # create nagios user
  nagios_contact { $name:
    ensure        => $ensure,
    contactgroups => $contactgroups,
    alias         => $alias,
    use           => $use,
    email         => $email,
    tag           => hiera('nagios_server'),
  }
}
