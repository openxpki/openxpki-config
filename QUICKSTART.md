# OpenXPKI Quickstart Guide

*Prerequisites*: You have installed the OpenXPKI packages and the apache webserver and have a working database installation in place and have the contents of the configuration repository copied to `/etc/openxpki`.

The default configuration comes with a realm named `democa` which is used in this documentation as placeholder whenever a step needs to be done for a special realm. You need to replace `democa` with the actual name of the realm you are working on.

All commands given in this document assume `/etc/openxpki` as working directory to resolve relative path.

### Init Database

You can find the schema for the supported database systems in `contrib/sql` - choose the one for your favorite RDBMS and create the initial schema from it. SQLite should not be used for production setups as it is not thread-safe and does not support all features.

Place the connection details for the database in `config.d/system/database.yaml`.

Note that the driver names are case sensitive: `MariaDB`, `MariaDB2`, `MySQL`, `PostgreSQL`, `Oracle`.

As we need some capabilities of the server process for the next steps, please start the
server now:

```bash
    $ systemctl start openxpki-serverd
```

You can watch the startup via `journalctl -u openxpki-serverd -f`:

```
   Starting openxpkid.service - OpenXPKI Trustcenter Backend...
   Started openxpkid.service - OpenXPKI Trustcenter Backend.
   Starting OpenXPKI Community Edition v3.32.0
   Modules: core
   OpenXPKI initialization finished
```

Depending on the size of your configuration and the ressources of the machine
the startup process can take several seconds. The system is ready to be used
when the socket file was created at `/run/openxpkid/openxpkid.sock`.

In the process list, you should see two process running:

```bash
    14302 ?        S      0:00 openxpki watchdog ( main )
    14303 ?        S      0:00 openxpki server ( main )
```

If this is not the case, check the systemd log and `/var/log/openxpki-server/stderr.log`.

### Setup Tokens

While the default configuration keeps most of the keys and certificates internally
in the database, at least the DataVault key should be kept on disk. This token is
usually shared across all realms and resides in `/etc/openxpki/local/keys`.

If you plan to keep also your other key files on disk, we recommend to add one
directory per realm under this path and keep them there.

#### Internal Datavault

Create a key for the Datavault Token (RSA 3072) and use this key to create a self-signed certificate
with a validity of one year. Extenstions and common name are provided via the given config file.

```bash
$ mkdir -p -m755 /etc/openxpki/local/keys
$ cd /etc/openxpki/local/keys
$ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -aes-256-cbc \
	-out vault-1.pem
$ openssl req -config /etc/openxpki/contrib/vault.openssl.cnf -x509 -days 365 \
	-key vault-1.pem -out vault-1.crt
```

Please make sure to keep a copy of this key and the certificate in a safe place
as you will need it to restore database encryption in case of a disk failure. If
you set up more then one node, please copy the **same** key file to the given
location on **all nodes**. There is no need to copy the certificate as this is
kept in the database. As the password does not add any extra security when it is
kept as literal in the config, it is also possible to use an unencrypted key. In any
case make sure that the access permissions are properly set so the OpenXPKI server
can read the file - recommended settings are permissions set to 0400 owned by the
`openxpki` user.

If you used a passphrase, put it into the default secret group found in the file
`config.d/system/crypto.yaml`.

Now import the certificate into OpenXPKI:

```bash
    $ openxpkiadm certificate import --file vault.crt

    Starting import
    Successfully imported certificate into database:
      Subject:    CN=Internal DataVault
      Issuer:     CN=Internal DataVault
      Identifier: YsyZ4eCgzHQN607WBIcLTxMjYLI
      Realm:      none
```

Register it as datasafe token for the `democa` realm, if you have multiple
realms, you must run the second command for each realm:

```bash
    $ openxpkiadm alias --realm democa --token datasafe \
        --file vault.crt

    Successfully created alias in realm democa:
      Alias     : vault-1
      Identifier: YsyZ4eCgzHQN607WBIcLTxMjYLI
      NotBefore : 2020-07-06 18:54:43
      NotAfter  : 2030-07-09 18:54:43
```

You should check now if your DataVault token is working::

```bash
    $ openxpkicli get_token_info --arg alias=vault-1
    {
        "key_name" : "/etc/openxpki/local/keys/vault-1.pem",
        "key_secret" : 1,
        "key_store" : "OPENXPKI",
        "key_usable" : 1
    }
```

If you do not see `"key_usable": 1` your token is not working! Check the
permissions of the file (and the folders) and if the key is password
protected if you have the right secret set in your crypto.yaml!

#### Issuing CA

The creation and management of the Issuing CA keys and certificates themselves
is **not** part of OpenXPKI, you need to have the keys and certificates at hand
before you proceed. We recommend the [clca-Tool](https://github.com/openxpki/clca)
for this purpose.

If you have a 2-Tier hierarchy, please import the Root CA certificate before you proceed:

```bash
$ openxpkiadm certificate import --file root.crt
```

If you have multiple roots or a deeper hierarchy please import all certificates that will not be signer tokens to the current installation. Always start with the self-signed root.

##### Software Keys in Database

The default configuration uses the database as storage for the encrpyted key blobs - if you think this does not meet your security requirements you can store the key blobs in the filesystem as described in the next section.

The `openxpkiadm alias` command offers a shortcut to import the certificate,
register the token and store the private key. Repeat this step for all issuer
tokens in all realms. The system will assign the next available generation
number and create all required internal links. The prerequisite to use this command is a running OpenXPKI server with a working DataVault token.

Before you import the keys, ensure that the keys are either unencrpyted or the password
used matches the secret referenced in the realms `crypto.yaml`. Both files must be PEM
encoded, make sure that you have imported the root ca certificate before.

```bash
$ openxpkiadm alias --realm democa --token certsign --file signer.crt --key signer.pem
```
The command will show the generated alias identifier (on an inital setup this is `ca-signer-1`), your realm should now look like (ids and times will vary)

```bash
    $ openxpkiadm alias --realm democa

    === functional token ===
    vault (datasafe):
    Alias     : vault-1
    Identifier: lZILS1l6Km5aIGS6pA7P7azAJic
    NotBefore : 2015-01-30 20:44:40
    NotAfter  : 2016-01-30 20:44:40

    ca-signer (certsign):
    Alias     : ca-signer-1
    Identifier: Sw_IY7AdoGUp28F_cFEdhbtI9pE
    NotBefore : 2015-01-30 20:44:40
    NotAfter  : 2018-01-29 20:44:40

    === root ca ===
    current root ca:
    Alias     : root-1
    Identifier: fVrqJAlpotPaisOAsnxa9cglXCc
    NotBefore : 2015-01-30 20:44:39
    NotAfter  : 2020-01-30 20:44:39
```

To check if the signer token was loaded properly and is operational run:

```bash
$ openxpkicli is_token_usable --realm=democa --arg alias=ca-signer-1
```

If anything went fine, this should print a literal `1`.

Another easy check to see if the signer token is really working is to
create a CRL

```bash
    $ openxpkicmd  --realm democa crl_issuance
    Workflow created (ID: 511), State: SUCCESS
```

##### Software Keys in Filesystem

In case you want to have your key blobs in the local filesystem, you can directly place the keys in the correct locations yourself and omit the `--key` flag on the alias command.

The alias command also works with local files, but you need to create the parent folders with suitable permissions yourself and you must run the command as root as the script will set the permissions on the files when creating them.

#### SCEP Token

The SCEP certificate should be a TLS Server certificate issued by the PKI. You can import it the same way as the other tokens:

```bash
openxpkiadm alias --realm democa --token scep --file scep.crt --key scep.pem
```

### WebUI and Enrollment Endpoints

Starting with v3.32 the webserver acts as a reverse proxy only and the application server runs as a dedicated process:

```bash
    $ systemctl start openxpki-clientd
```

Startup logs of the process are logged via systemd, the application itself logs to `/var/log/openxpki-client`.

You can find a working configuration for the Apache webserver in `contrib/apache2-openxpki-site.conf` - copy or symlink this to your webservers config directory (`/etc/apache2/sites-enabled/` on debian). This config exposes SCEP on Port 80 and the WebUI as well as the RPC and EST APIs on Port 443 via HTTPS.

The configuration expects the TLS key in `/etc/openxpki/tls/private/openxpki.pem` and the certificate (including its chain as concatenated PEM bundle) in`/etc/openxpki/tls/endentity/openxpki.crt`.

The default configuration also offers TLS client authentication. You need to
place a copy of your root certificate in `/etc/openxpki/tls/chain/` and run
`c_rehash /etc/openxpki/tls/chain/` to make it available for chain construction
in apache. If you don't want to use client authentication you must remove the
`SSLCACertificatePath` and `SSLVerify*` options as the webserver will not start
if this path is empty.


#### Realm Seletion

Please check the comments in the `client.d/service/webui/default.yaml` file
regarding the selection of realms by either URL path, virtual hosts or
cookies. You need to adjust this to your backend configuration to be able to
reach your realms.

#### Session Storage

The default configuration uses a database backend to store the webui
session information. Please review the section `session` and in
`client.d/service/webui/default.yaml`. It is strongly advised to use
a dedicated user here with access only to the `frontend_session` table
for security reasons. You can even put this on a different database as
the information is not used by the backend.

If you have a single node setup, you can switch to the filesystem based
driver.
