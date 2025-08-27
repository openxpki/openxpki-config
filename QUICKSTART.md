# OpenXPKI Quickstart Guide

*Prerequisites*: You have installed the OpenXPKI packages and the apache webserver and have a working database installation in place and have the contents of the configuration repository copied to `/etc/openxpki`.

The default configuration comes with a realm named `democa` which is used in this documentation as placeholder whenever a step needs to be done for a special realm. You need to replace `democa` with the actual name of the realm you are working on.

All commands given in this document assume `/etc/openxpki` as working directory to resolve relative path.

## Init Database

You can find the schema for the supported database systems in `contrib/sql` - choose the one for your favorite RDBMS and create the initial schema from it. SQLite should not be used for production setups as it is not thread-safe and does not support all features.

Place the connection details for the database in `config.d/system/database.yaml`.

Note that the driver names are case sensitive: `MariaDB`, `MariaDB2`, `MySQL`, `PostgreSQL`, `Oracle`. The driver `MariaDB` should no longer be used, please use `MariaDB2` and install `libdbd-mysql-perl` as the corresponding driver library.

### Frontend Session Storage

If you want to run OpenXPKI on more then one node, you should use the database also to store the frontend sessions.
It is advised to create a dedicated user for this who has permissions to the table `frontend_session` only.

See below section *Session Storage* for details.

## Setup global access user for command line interface (v3.32+)

To run protected commands and commands outside a realm using the `oxi` command line interface you must configure a key pair for authentication.

### Create a key pair

You need a EC key pair with curve `prime256v1`:

```bash
$ oxi cli create

    Please enter password to encrypt the key (empty to skip):
    Please retype password:
    ---
    id: YIDR0GocM-e78JPI9dXoaDBYJxKiV2bE7Cy72ErFjg4
    private: |
        -----BEGIN EC PRIVATE KEY-----
        ....
        -----END EC PRIVATE KEY-----
    public: |
        -----BEGIN PUBLIC KEY-----
        .....
        -----END PUBLIC KEY-----
```

### Deploy key pair

The public key must be added to `config.d/system/cli.yaml`, please ensure proper indent.

The private key is expected in the users home directory at `~/.oxi/client.key`.
If you want to multiple keys, you can also place them anywhere else and reference them using `--auth-key <filename>`.

> [!TIP]
> We recommend to not use the `root` user to maintain the pki so this setup must be done for your operational account. To allow this user access to the backend, you must assign it to the `openxpkiclient` group.

## Setup credentials for crypto layer

The crypto layer requires several passwords to be added to the configuration layer, in the default configuration
those secrets are shared across all realms and are defined in `config.d/system/crypto.yaml`.

The `default` secret is used to protect any token which has no other secret configured.
This is the password that is used to decrypt the private key for your issuer certificate and, if used,
for the keys of certificate based datavault tokens.

The `ratoken` secret is used to protect the internal token used for e.g. the SCEP server.

For both secrets you can choose any printable string, make sure to use this password when you
create the private keys for the associated tokens.

The `svault` secret is used directly as master secret for the datavault when using the *symmetric vault*
feature. It **must** be 32 byte value encoded in hexadecimal notation. The easiest way to generate such
a key is `openssl  rand -hex 32`. Please keep this value in a safe and secure place, if you loose it, you
will not be able to access any data protected by the datavault! This also implies that changing the secret
on an existing system requires a migration of any existing encrypted data to keep it accessible.

## Server start

As we need some capabilities of the server process for the next steps, please start the
server now:

```bash
$ systemctl start openxpki-serverd
```

You can watch the startup via `journalctl -u openxpki-serverd -f`:

```bash
   Starting openxpkid.service - OpenXPKI Trustcenter Backend...
   Started openxpkid.service - OpenXPKI Trustcenter Backend.
   Starting OpenXPKI Community Edition v3.32.8
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
Test if the socket is responsive and if your command line is working:

```bash
$ oxi cli ping
---
result: ok
```

## Setup Tokens

While the default configuration keeps most of the keys and certificates internally
in the database, at least the datavault key should be kept on disk. This token is
usually shared across all realms and resides in `/etc/openxpki/local/keys`.

If you plan to keep also your other key files on disk, we recommend to add one
directory per realm under this path and keep them there.

### Internal datavault

As of release v3.32 you can use a configured secret for datavault encryption.
The configuration is found in `crypto.yaml` of each realm.

#### Symmetric vault

Uses the value of the secret named `svault` as master secret for the datavault.
See the secion about the `svault` secret above.

```yaml
type:
    datasafe: svault

token:
    svault:
        class: OpenXPKI::Crypto::Token::Vault
        secret: svault

secret:
    svault:
        import: 1
```

#### Asymmetric vault

Uses an asymmetric key stored on disk wrapped by a certificate.

```yaml
type:
    datasafe: vault

token:
    vault:
        <<: *default_token
        key_store: OPENXPKI
        key: /etc/openxpki/local/keys/[% ALIAS %].pem
```

Create a key for the datavault Token (RSA 3072) and use this key to create
a self-signed certificate with a validity of one year. As password for the
key use the value of the `default` secret.

Extensions and common name are provided via the given config file.

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
kept in the database.

As the password does not add any extra security when it is kept as literal in the
config, it is also possible to use an unencrypted key. In any case make sure that
the access permissions are properly set so the OpenXPKI server can read the file.
Recommended settings are permissions set to 0400 owned by the `openxpki` user.

Now import the certificate into OpenXPKI:

```bash
$ oxi certificate add --cert vault.crt

authority_key_identifier: 6A:27:.....
cert_key: '433574019735366670028372053724009989262881985315'
identifier: 7Q6xOQjPrljk-zvK3fP5R-CiwGk
issuer_dn: CN=DataVault
issuer_identifier: 7Q6xOQjPrljk-zvK3fP5R-CiwGk
notafter: 1758896677
notbefore: 1756304677
status: ISSUED
subject: CN=DataVault
subject_key_identifier: 6A:27:.....

```

Register it as datasafe token for the `democa` realm, if you have multiple
realms, you must run the second command for each realm:

```bash
$ oxi token add --realm democa --type datasafe --cert vault.crt
```

You should check now if your datavault token is working::

```bash
$ oxi api get_token_info --realm democa -- alias=ca-signer-13
---
key_cert: |-
  -----BEGIN CERTIFICATE-----
  MIICKjCCAbCgAwIBAgIUbInV3gBtlgOvvMuFtm4OmQosXU0wCgYIKoZIzj0EAwIw
  .....
  Q1P2zfv12vWifAVaK/TYvHIaVd7MmOoP3386l1Z9
  -----END CERTIFICATE-----
key_cert_identifier: 7Q6xOQjPrljk-zvK3fP5R-CiwGk
key_engine: none
key_name: /etc/openxpki/local/keys/vault-1.pem
key_secret: 1
key_store: OPENXPKI
key_usable: 1
```

If you do not see `"key_usable": 1` your token is not working! Check the
permissions of the file (and the folders) and if the key is password
protected if you have the right secret set in your crypto.yaml!

### Issuing CA

The creation and management of the Issuing CA keys and certificates themselves
is **not** part of OpenXPKI, you need to have the keys and certificates at hand
before you proceed.

We recommend the [clca-Tool](https://github.com/openxpki/clca) for this purpose.

If you have a 2-Tier hierarchy, please import the Root CA certificate before you proceed:

```bash
$ oxi token add --realm rootca --type certsign --cert rootca.crt
```

If you have multiple roots please import all of them. If you have a deeper hierarchy, use the `oxi certificate` command to add all intermediate chain certificates which will not become a certsign token.
 Always start with the self-signed root.

#### Software Keys in Database

The default configuration uses the database as storage for the encrpyted key blobs - if you think this does not meet your security requirements you can store the key blobs in the filesystem as described in the next section.

The `oxi token` command offers a shortcut to import the certificate,
register the token and store the private key. Repeat this step for all issuer
tokens in all realms. The system will assign the next available generation
number and create all required internal links. The prerequisite to use this command is a running OpenXPKI server with a working datavault token.

Before you import the keys, ensure that the keys are either unencrpyted or the password
used matches the secret referenced in the realms `crypto.yaml`. Both files must be PEM
encoded, make sure that you have imported the root ca certificate before.

```bash
# import issuing ca
$ oxi token add --realm democa --type certsign --cert issuingca.crt --key issuingca.key
```
The command will show the generated alias identifier (on an inital setup this is `ca-signer-1`), your realm should now look like (ids and times will vary)

```bash
    $ oxi token list --realm democa
---
token_groups:
  ca-signer:
    active: ca-signer-1
    count: 1
    token:
    - key_cert_identifier: H_axbImE204U9aBodvn71ACKP4w
      key_engine: none
      key_name: ca-signer-1
      key_secret: 1
      key_store: DATAPOOL
      key_usable: 1
  ratoken:
    active: ratoken-1
    count: 1
    token:
    - key_alg: RSA
      key_cert_identifier: PncLigICYwNtLeWp45jAVCodEy4
      key_engine: none
      key_name: DF:2C:5E:23:DE:69:A7:99:0C:FE:9F:E7:B4:A6:C3:2A:AB:7B:09:4D
      key_secret: 1
      key_store: DATAPOOL
      token_id: PncLigICYwNtLeWp45jAVCodEy4
  token_types:
    certsign: ca-signer
    cmcra: ratoken
    datasafe: svault
    scep: ratoken

```

An easy check to see if the signer token is working is to create a CRL

```bash
$ oxi workflow create --realm democa --type crl_issuance
workflow:
  ....
  state: SUCCESS
```

#### Software Keys in Filesystem

In case you want to have your key blobs in the local filesystem, you can directly place the keys in the correct locations yourself and omit the `--key` flag on the alias command.

The alias command also works with local files, but you need to create the parent folders with suitable permissions yourself and you must run the command as root as the script will set the permissions on the files when creating them.

### SCEP Token

The SCEP certificate should be a TLS Server certificate issued by the PKI. You can import it the same way as the other tokens:

```bash
$ oxi token add --realm democa --type scep --cert ratoken.crt --key ratoken.key
```

## WebUI and Enrollment Endpoints

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

### Realm Seletion

Please check the comments in the `client.d/service/webui/default.yaml` file
regarding the selection of realms by either URL path, virtual hosts or
cookies. You need to adjust this to your backend configuration to be able to
reach your realms.

### Session Storage

The default configuration uses the filesystem to store the sessions for the WebUI.

To support continous sessions over multiple nodes you must use a database.
Please review the section `session` in `client.d/service/webui/default.yaml`.

It is strongly advised to use a dedicated user here with access only to the
`frontend_session` table for security reasons. You can even put this on a
different database as the information is not used by the backend.