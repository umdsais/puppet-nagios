# Create a Nagios contactgroup
define nagios::contactgroup (
  $ensure = present,
  $alias  = undef,
  $members = undef,
  $use = undef,
) {
  nagios_contactgroup { $name:
    ensure  => $ensure,
    alias   => $alias,
    members => $members,
    use     => $use,
  }
}
