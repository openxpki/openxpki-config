## SCEP Endpoint Setup

The SCEP service is organized by so called *endpoints* which couples
a service URL with a frontend and a backend configuration.

The default configuration comes with an endpoint called `generic`, which
is connected to the URL `http://my.example.com/scep/generic`. Some clients
append `pkiclient.exe` or similar to the URL path, this is no problem as
long as the URL starts with `/scep/<endpoint>`, so e.g.
`http://my.example.com/scep/generic/pkiclient.exe` is a valid URL for the
`generic` endpoint.

### Adding a new endpoint

The `endpoint.conf-template` file provides a default configuration that
works in most standard cases. To add an endpoint, just create a copy of
(or symlink) the file to `<endpoint>.conf` **and** create a backend
configuration with the same name in `realm/yourca/scep/<endpoint>.yaml`.

You can take the existing, well documented, `generic.yaml` as an example.

### Warning

Note that `http://my.example.com/scep/pkiclient.exe` or even
`http://my.example.com/scep` are **not valid SCEP URLs**. It *might* be
the case that such URLs work partially and return a valid response to a
`GetCACert` or `GetCACaps` as those have a builtin default behaviour, but
such URLs *will* definitily fail on any enrollment request as required
configuration is missing!

Same applies if you have a frontend configuration without a backend
configuration!
