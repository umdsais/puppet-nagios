# Short defined type which is used by clients to create suitable Nagios hostgroups
# for themselves as exported resources without risk of duplication
define nagios::hostgroup (
  String $hostgroup,
  String $hostgroupalias,
) {
  ensure_resource('nagios_hostgroup', $hostgroup, {
    'alias'  => $hostgroupalias,
    'ensure' => 'present',
    'owner'  => 'root',
    'group'  => 'nagios',
    'mode'   => '0644',

  })
}
