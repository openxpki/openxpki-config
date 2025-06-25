# OpenXPKI Upgrade Hints

We try hard to build releases that do not break old installations but
sometimes we are forced to make changes that require manual adjustment
of existing config or even the database schema.

Please read the sections below **before** you upgrade the code packages.

## Release v3.32

This release has several breaking changes you must address when upgrading:

* Mandatory version identifiers in config
* Updates to YAML config due to new YAML parser
* Realm URLs must be unique
* New socket and permission layout
* Changed logfile locations (only with new frontend)

This release also introduces a new technical layer for the frontends
which comes with a new configuration layout and is the default when you
install the system from scratch. We recommend to migrate you existing
configuration to the new system. The old layer is still supported but
you need to make some minor adjustments to your configuration to run it.

### Socket and permissions

The frontend client now runs as a dedicated process and the communication
sockets are now inside `/run`, permissions and process logic is now handled
mostly by systemd. The socket of the backend client is now at
`/run/openxpkid/openxpkid.sock`, the package installer creates a symlink
if the old location exists but it is easier to just remove the socket
location from all config files as the new release assumes the new location
as default in any place.

The owner and group permissions have been changed for the new layout, if you
want to run the old frontend, you need to adjust the permission so the
webserver can talk to the backend!

### Mandatory Versioning

Add the depend node in the file `system/version.yaml`:

```yaml
    depend:
      core: 3.32
      config: 2
```

You also *should* add a version identifier to the SQL tables, check if your
schema is up to date - instructions to add the schema are in the SQL files.

### YAML Update

OpenXPKI uses the pattern `+YYMMDD...` to specify relative dates in several
places. In the old configuration those are given as plain strings, e.g.

```yaml
    validity:
        notafter: +01
```

The new YAML parser interpretes this as number and strips the leading
zeros which leads to unexpected behaviour and malformat errors. Please
review your configuration and add quotes around:

```yaml
    validity:
        notafter: "+01"
```

### Logfiles

Folders for the logfiles are now created during package install, to not
interfere with legacy configurations the folders got new names.

#### Server Process

The new default location is `/var/log/openxpki-server`, but as the path
to the logfiles is explicitly given in the servers `log.conf` nothing
will change unless you upgrade your configuration to point to the new
target directory. The folder is now exclusive to the server daemon and
owned by `openxpki:pkiadm`, you *must* change your log.conf to enforce
the logfile owner to be `openxpki` as otherwise the daemon can not
create log files any longer.

#### Client (Frontend) Process

The new application server logs to `/var/log/openxpki-client`, the
target directory will not change if you stick with the old FCGI based
frontend wrappers.

### Realm URLs

Due to changes in the URL handling it is no longer possible to use
`/webui/index/` to log into the PKI with the old frontend code when only
one realm is configured. If you do not want to upgrade, use the realm map
and assign a dedicated name to your realm, e.g. `/webui/democa/`.
