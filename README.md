# nagios

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Classes](#classes)
       * [nagios](#nagios)
       * [nagios::client](#nagiosclient)
    * [Resources](#resources)
       * [nagios::service](#nagiosservice)
4. [Examples](#examples)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs and manages [Nagios](https://www.nagios.org/), [NRPE](https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details#_ga=2.77165653.1717758004.1498228250-1930082806.1498228250), [NSCA](https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details#_ga=2.77165653.1717758004.1498228250-1930082806.1498228250), [BPI](https://exchange.nagios.org/directory/Addons/Components/Nagios-Business-Process-Intelligence-&#40;BPI&#41;/details) and [PNP4Nagios](https://docs.pnp4nagios.org/) to give you a full monitoring stack.

## Module Description

While Nagios itself is not too complex, a full stack installation includes a number of optional components. Let's have a look at the terminology - if you are new to Nagios you should definitely read and understand the definitions before attempting to use this module.

This module is quite opinionated about how Nagios should be set up. I've made it as configurable as I can without deviating from the model that I believe is best, which has been extensively tested in our local environment before publishing. It makes assumptions about how you want to group things that mean you can start benefiting from Nagios quickly without having to set too much up.

This module makes heavy use of [Puppet exported resources](https://docs.puppet.com/puppet/4.10/lang_exported.html) to configure Nagios. You **must** have a working Puppet and PuppetDB environment with exported resources before using this module.

**Warning**: This module uses [`puppetlabs/apache`](https://forge.puppet.com/puppetlabs/apache) to configure the web frontend. Be aware that `puppetlabs/apache` will **purge** all other Apache config that is not managed with `puppetlabs/apache`. This Nagios module with play nicely with other web sites configured with `apache::vhost` but it will break anything else that has been configured manually.

### Nagios

Nagios is the name of the main monitoring application, and it includes a web application and a backend daemon. The daemon does the actual monitoring by executing plugins which send probes to clients, and then displaying the results in the web application or sending them via notifications.

Be careful with the terminology: here we use *server* to refer to the Nagios server, and *client* to refer to the Nagios clients, even though they may be servers in their own right.

```
+--------+      +--------+
| Nagios | ---> | Client |
+--------+      +--------+
```

### NRPE

While Nagios is good at sending probes to clients that are offering services (e.g. sending HTTP requests to web servers) it needs something extra to probe non-public aspects of a client, e.g. checking CPU usage.

To achieve this, we run the NRPE daemon on the client which listens for the server and executes plugins to probe the local system. The Nagios server probes NRPE on the client which runs the plugin and returns the result to Nagios.

```
+--------+      +--------+      +--------+
| Nagios | ---> |  NRPE  | ---> | Client |
+--------+      +--------+      +--------+
```

### NSCA

NSCA works the other way round from NRPE. NSCA runs on the server and listens for clients to submit passive checks to Nagios on their own schedule (e.g. via cron) rather than the Nagios server initiating the probes.

```
+--------+      +--------+      +--------+
| Nagios | <--- |  NSCA  | <--- | Client |
+--------+      +--------+      +--------+
```

### BPI

BPI (Business Process Intelligence) is an addon for Nagios which is able to model real-world applications based on a set of probes. For example: you may have a cluster of 2 web servers and so long as either server is up, the overall service is up. You might not care if only one server is down. BPI uses logic like this to work out if your real services are up or down and send appropriate alerts.

### PNP4Nagios

Some Nagios plugins return performance data as well as a status code. Out of the box, Nagios can't do anything with this data, but PNP4Nagios can process this data with RRD and automatically draw graphs.


## Usage

This module is designed so the base class `::nagios` configures a Nagios monitoring server. Other classes are available such as `::nagios::client` which configures a Nagios client to be monitored. There are also some defined types which should be directly called where necessary to configure extras.

### Classes

#### `::nagios`

The `::nagios` class installs a Nagios monitoring server and related components.

##### `client`
Install components to run a Nagios client, i.e. a server that is monitored. Default: `true`

##### `server`
Install components to run a Nagios monitoring server. Default: `false`

##### `nrpe`
Install support for NRPE, which is required if you want to execute Nagios checks on remote servers (clients). Default: `false`

##### `nsca`
Install support for NSCA, which is required if you want to execute passive Nagios checks. Default: `false`

##### `selinux`
Manage SELinux rules to allow Nagios components to run properly on the clients and server. Strongly recommended if you are running a Red Hat family distro, and SELinux is enabled on your system. Requires [`puppet/selinux`](https://forge.puppet.com/puppet/selinux). Default: `false`

##### `firewall`
Manage firewall rules on Nagios clients and server. Strongly recommended to allow Nagios components to work properly. Caution: firewall rules are managed by [`puppetlabs/firewall`](https://forge.puppet.com/puppetlabs/firewall). That module purges any firewall rules that are *not* managed with `puppetlabs/firewall` so be extremely careful before enabling this option. Default: `false`

##### `url`
Override the hostname that your Nagios server will run on, if you don't want it to run on the server's `$::fqdn`. Default: `$::fqdn`

##### `aliases`
Array of alternative hostnames that your Nagios server should respond to. Don't forget to set these as alternate names in your SSL certificate. Default: `[]`

##### `dev`
Set a flag to mark this Nagios server as a development/testing server. This suppresses active notifications from Nagios. Default: `false`

##### `serveradmin`
Server admin email address for use by Apache. Default: `root@localhost`

##### `auto_os_hostgroup`
Whether to automatically add this client to a hostgroup of its OS type. Default: `true`

##### `auto_virt_hostgroup`
Whether to automatically add this client to a hostgroup of its hardware/virtualised platform. Default: `true`

##### `hostgroups`
Array of other hostgroups to add the system to. Default: `[]`

##### `parent`
Name of a parent object. Default: `undef`

##### `nrpe_package`
Name of the NRPE package. You *shouldn't* need to override this. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `webroot`
Location of the webroot on the filesystem. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `cgiroot`
Location of the CGI root on the filesystem. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nsca_client_package`
Name of the NSCA client package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_service`
Name of the NRPE service. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_config`
Path to the NRPE config file. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_d`
Path to the NRPE conf.d directory. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_plugin_package`
Name of the NRPE plugin package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nsca_server_package`
Name of the NSCA server package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nsca_service`
Name of the NSCA service. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nsca_config`
Path to the NSCA config file. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nagios_package`
Name of the Nagios package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nagios_service`
Name of the Nagios service. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

#### `::nagios::client`

The `::nagios::client` class installs components needed for a system to be monitored by a Nagios monitoring server.

##### `nrpe`
Whether to enable support for NRPE. Default: `true`

##### `nsca`
Whether to enable support for NSCA. Default: `true`

##### `selinux`
Whether to manage SELinux policies to allow plugins to execute properly via NRPE. Default: `true`

##### `firewall`
Whether to manage firewall rules to allow plugin to execute properly via NRPE. Default: `true`

##### `basic_checks`
Whether to set up a basic set of checks that should work on all systems (e.g. ping). Default: `true`

##### `nrpe_package`
Name of the NRPE client package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nsca_client_package`
Name of the NSCA client package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_service`
Name of the NRPE service. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_config`
Path to the NRPE config file. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_d`
Path to the NRPE conf.d directory. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `nrpe_plugin_package`
Name of the NRPE plugin package. If you need to add support for a new distro, please send a pull request or [raise an issue](https://github.com/djjudas21/puppet-nagios/issues).

##### `ssl_cert`
Path to SSL server certificate. Default: `/path/to/cert.crt`

##### `ssl_key`
Path to SSL private key. Default: `/path/to/key.key`

##### `ssl_chain`
Path to SSL certificate chain file. Default: `undef`

##### `ssl_cipher`
Allowed SSL ciphers. Defaults to a more secure list than ships with [`puppetlabs/apache`](https://forge.puppet.com/puppetlabs/apache#ssl_cipher). Default: `HIGH:!MEDIUM:!aNULL:!MD5:!RC4:!3DES`


### Defined types

#### `nagios::service`

The `::nagios::service` defined type installs a service, a command and other related components required to monitor something.

##### `host_name`
Hostname of the system that the check should be associated with. Default: `$::fqdn`

##### `check_command`
Override the name of the check command in the service definition. Default: `$title`

##### `service_description`
Human-readable name for the service.

##### `use`
Name of the Nagios template to inherit from. Default: `undef`

##### `servicegroups`
One or more servicegroups that this service should be a member of. Default: `$title`

##### `add_servicegroup`
Whether to automatically create the servicegroup that this service belongs to by default. Default: `true`

##### `add_servicedep`
Whether to automatically add a service dependency on NRPE, if this service is a NRPE-based check. Default: `true`

##### `active_checks_enabled`
Whether to override active checks. Default: `undef`

##### `max_check_attempts`
Whether to override the maximum number of check attempts before reporting hard state. Default: `undef`

##### `check_freshness`
Override check freshness. Probably only useful for passive checks. Default: `undef`

##### `freshness_threshold`
Override freshness threshold. Probably only useful for passive checks. Default: `undef`

##### `command_definition`
The command line used to execute the plugin. The default can be used only if no arguments are required. Default: `$check_command`

##### `check_interval`
Override the check interval on a per-service basis. This is usually inherited from a template with `use`. Default: `undef`

##### `use_nrpe`
Whether to execute this check on the monitored host via NRPE. Default: `false`

##### `use_sudo`
Whether to use sudo when executing this check. Default: `false`

##### `sudo_user`
The username to use when executing plugins with sudo when `$use_sudo = true`. Default `undef`

##### `install_plugin`
Whether to install the Nagios plugin on the system. Default: `true`

##### `plugin_provider`
Provider for the plugin installation, if `$install_plugin = true`. Default: `package`

##### `plugin_source`
Source for installation of the plugin if `$install_plugin = true`. Default: `undef`

##### `service_dependency`
Add arbitrary service dependencies on other services on this host. Default: `undef`

##### `nagios_server`
The hostname of the Nagios server that will be monitoring this host. Default: `hiera('nagios_server')`

## Examples

### Install a Nagios server

```puppet
class ::profile::nagios {
  # Install Nagios server
  class { 'nagios':
    nrpe        => true,                     # Set up NRPE for monitoring of remote hosts
    nsca        => false,                    # Skip NSCA, which is needed for passive checks
    selinux     => true,                     # Manage SELinux policies to allow Nagios to run smoothly
    firewall    => true,                     # Manage firewall rules to allow Nagios/NRPE to run smoothly
    url         => 'nagios.example.com',     # Service URL of Nagios, if different from the system hostname
    serveradmin => 'root@example.com',       # Admin's email address
    ssl_cert    => '/etc/pki/tls/certs/nagios.example.com.pem',  # Path to SSL cert for HTTPS
    ssl_key     => '/etc/pki/tls/private/nagios.example.com.key',  # Path to SSL key for HTTPS
    auth_type   => 'CAS',                    # Override Apache basic auth and use CAS single sign-on instead
  }

  # Deploy HTTPS certificate
  file { '/etc/pki/tls/certs/nagios.example.com.pem':
    source => 'puppet:///modules/profile/nagios/nagios.example.com.pem',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }

  # Deploy HTTPS private key
  file { '/etc/pki/tls/private/nagios.example.com.key':
    source => 'puppet:///modules/profile/nagios/nagios.example.com.key',
    mode   => '0600',
    owner  => 'root',
    group  => 'root',
  }
}
```

### Basic non-NRPE service

This service definition monitors the host remotely, directly from the Nagios server. This is
ideal for monitoring services that are available on the remote host, such as HTTP.

```puppet
nagios::service { 'check_http':
  service_description => 'HTTP',
  plugin_source       => 'nagios-plugins-http',
  command_definition  => 'check_http -I $HOSTADDRESS$ $ARG1$',
}
```

### Basic NRPE service

This service definition installs the plugin on the monitored host and configures NRPE. The check
itself is installed on the Nagios server. This is ideal for monitoring attributes of the remote
host that are not available externally.

```puppet
nagios::service { 'check_users':
  use_nrpe            => true,                       # Execute this on the host via NRPE
  service_description => 'Current users',            # Human-readable description
  plugin_source       => 'nagios-plugins-users',     # Package that provides this plugin
  command_definition  => 'check_users -w 10 -c 20',  # Syntax for actually calling the plugin
}
```

### Service running on an unmanaged host

This service definition is applied to the Nagios server, and the host name is overridden
to point at a different system (one that is not managed by Puppet). This is ideal for
monitoring "dumb" devices such as switches or other people's servers that you have no
access to.

```puppet
nagios::service { 'check_ping_router':
  host_name           => 'router.example.com',
  plugin_source       => 'nagios-plugins-ping',
  service_description => 'Ping',
  command_definition  => 'check_ping -H $HOSTADDRESS$ -w 100,10% -c 1000,50% -p 5',
}
```

### Service running on a manually managed host

This service definition is applied to the Nagios server and the host name is overriden
to point at a different system which is manually managed, and has a manually-configured
NRPE agent but no Puppet agent. This is ideal for monitoring legacy servers where you
can't retrofit Puppet.

```puppet
nagios::service { 'check_load_legacysystem.example.com':
  check_command       => 'check_load',                 # Name of the command we have manually set on the remote system
  use_nrpe            => true,                         # Use NRPE, which we have manually set up
  service_description => 'Load',
  host_name           => 'legacysystem.example.com',   # Override monitored server name
  install_plugin      => false,                        # Don't attempt to manage the plugin
}
```

## Limitations

This module has been developed for Nagios 4 on CentOS 7. It's pretty flexible so it should work on other platforms too but they have had little-to-no testing.

This module is currently functional but not feature-complete. There are rough edges and things not implemented yet. Please look at the
[issue tracker](https://github.com/djjudas21/puppet-nagios/issues) to look for outstanding issues and feature requests.

In particular the HTTPS/SSL config is rough around the edges and quite a few options are hard-coded in and need to be brought out to parameters.

## Development

This module was written initially for internal use - features we haven't needed to use probably haven't been written. Please send pull requests with new features and bug fixes. You are also welcome to file [issues](https://github.com/djjudas21/puppet-nagios/issues) but I make no guarantees of development effort if the features aren't useful to my employer.
