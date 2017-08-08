# Short defined type which is used by clients to create suitable Nagios servicegroups
# for themselves as exported resources without risk of duplication
define nagios::servicegroup (
  $groupname,
  $groupalias = undef,
  $target,
) {
  ensure_resource('nagios_servicegroup', $groupname, {
    'alias'  => $groupalias,
    'ensure' => 'present',
    'target' => $target,
    'owner'  => 'root',
    'group'  => 'nagios',
    'mode'   => '0644',
  })
}
