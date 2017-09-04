# Short defined type which is used by clients to create suitable Nagios commands
# for themselves as exported resources without risk of duplication
define nagios::command (
  $command_name,
  $command_line,
) {
  ensure_resource('nagios_command', $command_name, {
    'command_line' => $command_line,
    'ensure'       => 'present',
    'owner'        => 'root',
    'group'        => 'nagios',
    'mode'         => '0644',
  })
}
