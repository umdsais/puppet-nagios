# Create Nagios users
define nagios::user (
  String $alias=undef,
  String $email=undef,
  String $use = 'generic-contact',
  String $ensure=present,
  String $contactgroups = undef,
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
