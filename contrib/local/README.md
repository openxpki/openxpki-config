# Boilerplate and Template Folder

It is recommended to put files that hold credentials or host/environment
dependant items in the folder `/etc/openxpki/local` and do *NOT* add them
to the version control system.

This folder should be used to provide template files to be copied (and
adjusted) to `/etc/openxpki/local`.

Files holding sensitive information and used by the OpenXPKI backend
should be owned by `root:openxpki` with permissions set to `0640`.

Files holding sensitive information and used by the OpenXPKI frontend
should be owned by `root:openxpkiclient` with permissions set to `0640`.

Any files not holding sensitive data can be set to `0644` owned by
`root:root`.
