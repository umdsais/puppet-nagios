# Create a Nagios contactgroup
define nagios::contactgroup (
  String $ensure = present,
  String $alias  = undef,
  String $members = undef,
  String $use = undef,
) {
  nagios_contactgroup { $name:
    ensure  => $ensure,
    alias   => $alias,
    members => $members,
    use     => $use,
  }
}
