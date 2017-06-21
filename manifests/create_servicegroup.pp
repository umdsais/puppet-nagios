# Short defined type which is used by clients to create suitable Nagios servicegroups
# for themselves as exported resources without risk of duplication
define nagios::create_servicegroup (
  $groupname,
  $groupalias = undef,
) {
  ensure_resource('nagios_servicegroup', $groupname, {'alias' => $groupalias, 'ensure' => 'present'})
}
