# Installs the nagios plugin itself from arbitrary sources
# e.g. package, vcsrepo, file
define nagios::plugin (
  $plugin_provider,
  $plugin_source,
) {
  ensure_resources($plugin_provider, $plugin_source)
}
