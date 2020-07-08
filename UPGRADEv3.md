## System

### Session Handler

The internal session handler `openxpki` is no longer supported. We recommend to use `driver:openxpki` which is an improved version of CGI:Session::DBI. On debian, the driver is available as an extra package `openxpki-cgi-session-driver`

### Authentication

The syntax for the Authentication::ClientX509 handler has changed. The
keywords `realm` and `cacert` to set the trust anchors are now keys below
to the new node `trust_anchor`:

```yaml
trust_anchor:
    realm: user-ca
    cacert: zJovVgaxAFthT4TXDRP9VyhFrBY
```

### SCEP

The old SCEP tools dont work with OpenSSL 1.1, so if you are upgrading to
Buster you must install the libscep packages and change the config to use
the new SCEP layer. Affected files are `config.d/system/server.yaml`,
`config.d/system/crypto.yaml`, `config.d/<realm/crypto.yaml` and the SCEP
wrapper configs in `scep/`.

### ACL

The per command ACL feature is now active by default on the socket interface.
Create a node `api.acl.disabled: 1` in each realm config to keep the old
behaviour or deploy your own ACLs, see OpenXPKI::Server::API2.

## Workflow

### Enrollment (certificate_enroll)

#### Changed Class Names

Class ...SCEPv2::CalculateRequestHMAC was renamed to ...Tools::CalculateRequestHMAC

#### Workflow Parameters

For OnBehalf enrollments the `request_mode` is now set to *onbehalf* instead of *initial*. This also requires a seperate section *onbehalf* in the eligibilty section of the servers configuration::

```yaml
eligible:
    initial:
       value: 0

    renewal:
       value: 1

    onbehalf:
       value: 1
```

### Message of the Day (set_motd)

Legacy parameters used the set_motd action have been removed and need to be updated.


## Database

### Type Changes

* logtimestamp in application_log and auditlog should have 5 decimals (DECIMAL 20,5)

### New Fields (see schemas for details)

* crl.profile
* datapool.access_key
* workflow_archive_at
* crl.max_revocation_id
* certificate.revocation_id 
