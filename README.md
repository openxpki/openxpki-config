# OpenXPKI basic system configuration

This directory contains a minimum and complete configuration set to run
a OpenXPKI instance using the WebUI. All contents need to be copied to
/etc/openxpki/.

## Log configuration (log.conf)

OpenXPKI uses Log4perl for its logging system. The location of the
configuration file is set in the systems configuration, where the default
is /etc/openxpki/log.conf. The file is ready for use, just copy it.


## Global system configuration (config.d/system)

Global system configuration, such as path to binaries and database. Should do
as is on most systems, minimal action: configure your database.


## realm configuration (config.d/realm/)

A single OpenXPKI instance can be used to run more than one logical 
certification authority - we call this a "realm". A fully working config
can be found in realm.tpl, to setup a working CA either make a copy of this
directory or just create a symlink to it from inside the `realm` directory
and put the name of the realm in the file system/realms.yaml. 

A demo realm named "democa" is part of the repository. It is recommended to 
not use this for a production system.

