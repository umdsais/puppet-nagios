# Short defined type which is used by clients to create suitable Nagios hostgroups
# for themselves as exported resources without risk of duplication
define nagios::create_hostgroup (
  $hostgroup,
  $hostgroupalias,
) {
  ensure_resource('nagios_hostgroup', $hostgroup, {'alias' => $hostgroupalias, 'ensure' => 'present'})
}
