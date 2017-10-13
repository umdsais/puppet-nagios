# Short defined type which is used by clients to create suitable Nagios commands
# for themselves as exported resources without risk of duplication
define nagios::command (
  String $command_name,
  String $command_line,
) {

  # Strip off everything after the !, e.g. check_ping!192.168.0.1
  $trunc_command_name = regsubst($command_name, '^(.*)!?.*$', '\1')

  ensure_resource('nagios_command', $trunc_command_name, {
    'command_line' => $command_line,
    'ensure'       => 'present',
    'owner'        => 'root',
    'group'        => 'nagios',
    'mode'         => '0644',
  })
}
