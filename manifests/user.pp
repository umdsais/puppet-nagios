# Create Nagios users
define nagios::user (
  $alias=undef,
  $email=undef,
  $use = 'generic-contact',
  $ensure=present
) {
  # create nagios user
  nagios_contact { $name:
    ensure        => $ensure,
    contactgroups => 'admins',
    alias         => $alias,
    use           => 'generic-contact',
    email         => $email,
    tag           => hiera('nagios_server'),
  }
}
