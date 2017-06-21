# nagios

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs and manages Nagios, NRPE, NSCA, BPI and PNP4Nagios to give
you a full monitoring stack.

## Module Description

While Nagios itself is not too complex, a full stack installation includes a
number of optional components. Let's have a look at the terminology - if you are
new to Nagios you should definitely read and understand the definitions before
attempting to use this module.

### Nagios

Nagios is the name of the main monitoring application, and it includes a web
application and a backend daemon. The daemon does the actual monitoring by executing
plugins which send probes to clients, and then displaying the results in the web
application or sending them via notifications.

Be careful with the terminology: here we use *server* to refer to the Nagios server,
and *client* to refer to the Nagios clients, even though they may be servers in
their own right.

```
+--------+      +--------+
| Nagios | ---> | Client |
+--------+      +--------+
```

### NRPE

While Nagios is good at sending probes to clients that are offering services (e.g.
sending HTTP requests to web servers) it needs something extra to probe non-public
aspects of a client, e.g. checking CPU usage.

To achieve this, we run the NRPE daemon on the client which listens for the server
and executes plugins to probe the local system. The Nagios server probes NRPE on
the client which runs the plugin and returns the result to Nagios.

```
+--------+      +--------+      +--------+
| Nagios | ---> |  NRPE  | ---> | Client |
+--------+      +--------+      +--------+
```

### NSCA

NSCA works the other way round from NRPE. NSCA runs on the server and listens for
clients to submit passive checks to Nagios on their own schedule (e.g. via cron)
rather than the Nagios server initiating the probes.

```
+--------+      +--------+      +--------+
| Nagios | <--- |  NSCA  | <--- | Client |
+--------+      +--------+      +--------+
```

### BPI

BPI (Business Process Intelligence) is an addon for Nagios which is able to model
real-world applications based on a set of probes. For example: you may have a cluster
of 2 web servers and so long as either server is up, the overall service is up. You
might not care if only one server is down. BPI uses logic like this to work out if
your real services are up or down and send appropriate alerts.

### PNP4Nagios

Some Nagios plugins return performance data as well as a status code. Out of the
box, Nagios can't do anything with this data, but PNP4Nagios can process this data
and automatically draw graphs.


## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.
