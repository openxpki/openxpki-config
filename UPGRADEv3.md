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
