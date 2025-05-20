# OpenXPKI Configuration Repository

**Note**: Some of the items and features mentioned in this document are only accessible using the enterprise configuration which requires a support subscription.

## TL;DR

To start with your own configuration, clone the `community` branch to `/etc/openxpki` and read QUICKSTART.md.

	git clone https://github.com/openxpki/openxpki-config.git --branch=community /etc/openxpki

## How to Start

This repository holds a boilerplate configuration for OpenXPKI which must be installed to  `/etc/openxpki/`.

The upstream repository provides three branches:

| Branch         | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| **master**     | An almost empty branch that holds this README                |
| **community**  | The recommended branch for running an OpenXPKI Community Edition |
| **enterprise** | The recommended branch for running an OpenXPKI Enterprise Edition |

### Credentials / Local Users

Credentials and, if used, the local user database are kept in the folder `/etc/openxpk/local`. Those files will contain passwords in plain text and items like hostnames which will likely depend on the actual environment so we **do not recommend to add them to the repository** but deploy those on the machines manually or by using a provisioning system.

The files are already linked into the configuration layer and must be created before the system can be used. Templates for those files are provided in `contrib/local`, copy the directory  `cp -a /etc/openxpki/contrib/local /etc/openxpki` and adjust the files as needed.

### Define your Realms

Open `config.d/system/realms.yaml` and add your realms.

For each realm, create a corresponding directory in `config.d/realm/`, for a test drive you can just add a symlink to `realm.tpl`, for a production setup we recommend to create a directory and add the basic artefacts as follows:

```bash
mkdir workflow workflow/def profile notification
ln -s ../../realm.tpl/api/
ln -s ../../realm.tpl/auth/
ln -s ../../realm.tpl/crl/
ln -s ../../realm.tpl/crypto.yaml
ln -s ../../realm.tpl/uicontrol/
cp ../../realm.tpl/profile/default.yaml profile/
ln -s ../../../realm.tpl/profile/template/ profile/
cp ../../realm.tpl/notification/smtp.yaml.sample notification/smtp.yaml
ln -s ../../../realm.tpl/workflow/global workflow/
ln -s ../../../realm.tpl/workflow/persister.yaml workflow/
(cd workflow/def/ && find ../../../../realm.tpl/workflow/def/ -type f | xargs -L1 ln -s)
# In most cases you do not need all workflows and we recommend to remove them
# those items are rarely used
cd workflow/def
rm certificate_export.yaml certificate_revoke_by_entity.yaml report_list.yaml
# if you dont plan to use EST remove those too
rm est_cacerts.yaml est_csrattrs.yaml
```

We recommend to add the "vanilla" files to the repository immediately after copy and before you do **any** changes:

```bash
git -C /etc/openxpki add config.d/
git commit -m "Initial commit with Realms"
```

#### User Home Page

The default configuration has a static HTML page set as the home for the `User` role. The code for this page must be manually placed to `/var/www/static/<realm>/home.html`, an example can be found in the `contrib` directory. If you don't want a static page, remove the `welcome` and `home` items from the `uicontrol/_default.yaml`. If you want to use the same pages for all realms, put them into a folder named `_global`.

### Define Profiles

To issue certificates you need to define the profiles first. Adjust your realm wide CDP/AIA settings, validity and key parameters in `profile/default.yaml`.

For each profile you want to have in this realm, create a file with the profile name. You can find templates for most use cases in `realm.tpl/profile`, there is also a `sample.yaml` which provides an almost complete reference.

We recommend to have global settings, as most of the extensions, in the `default.yaml` and only put the subject composition and the key usage attributes in the certificate detail file.

### Customize i18n

The folder `contrib/i18n/` contains the translation files from the upstream project. If you need local extensions or want to change individual translations,  create a file named openxpki.local.po and make your changes here - **never touch the openxpki.po file itself**.

You can find a Makefile in the main folder, that can be used to create the required compiled files. Running `make mo` creates the `openxpki.mo` files in the language directories, `make mo-install` deploys them to the system. *Note*: it might be required to restart the webserver to make the changes visible.

### Version Tag

The WebUI status page can show information to identify the running config. The Makefile contains a target `make version` which will append the current commit hash to the file `config.d/system/version.yaml`. which will make the commit hash visible on the status page.

### File Permissions

The `config.d` folder and the credential files in `local` should be readable by the `openxpki` user only as they might contain confidential data.

The files for the protocol wrappers (`webui, scep, rpc, est, soap` ) must be readable by the webserver, if you add credentials here make sure to reduce the permissions as far as possible.

Starting with v3.32 the client wrappers are handled by a new service layer, it runs under its own user `openxpkiclient` and reads all configuration from `client.d`.

## Testing

To setup the templates for automated test scripts based on a KeyWordTesting Framework run `make testlib`. This will add a folder `contrib/test/` with sample files and the library classes.

We recommend to not add the `libs` path to the repository but to pull this on each test as the libraries will encapsulate any version dependent behavior.

## Packaging and Customization

By default, the package name for the configuration packages is 'openxpki-config', this can be customized  via the file `.customerinfo`. The format of this file is KEY=VALUE.

    PKGNAME=openxpki-config-acme
    PKGDESC="OpenXPKI configuration for Acme Corporation"

