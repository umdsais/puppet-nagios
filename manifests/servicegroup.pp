# Short defined type which is used by clients to create suitable Nagios servicegroups
# for themselves as exported resources without risk of duplication
define nagios::servicegroup (
  String $groupname,
  String $groupalias = undef,
) {
  ensure_resource('nagios_servicegroup', $groupname, {
    'alias'  => $groupalias,
    'ensure' => 'present',
    'owner'  => 'root',
    'group'  => 'nagios',
    'mode'   => '0644',
  })
}
