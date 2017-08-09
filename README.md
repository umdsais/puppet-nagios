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
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
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

##### `dev`
Set a flag to mark this Nagios server as a development/testing server. This suppresses active notifications from Nagios. Default: `false`

##### `serveradmin`
Server admin email address for use by Apache. Default: `root@localhost`

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

### Defined types

#### `nagios::service`

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

This module was written primarily for internal use - features we haven't needed to use probably haven't been written. Please send pull requests with new features and bug fixes. You are also welcome to file issues but I make no guarantees of development effort if the features aren't useful to my employer.
