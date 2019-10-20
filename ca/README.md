### Private Key Directory

This is the right place to put the key files of your OpenXPKI installation.

**CA Signer Token**: The default pattern of the CA signing keys is `<realm-name>/ca-signer-<X>.pem` where `<X>` is again the generation number and `<realm-name>` is the name of the realm (same as the name of the realm directory below `config.d/realm`).

**Data Vault Token**: It is usually a good idea to share the vault token over all realms, therefore the tokens file name is `vault-<X>.pem` located in this directory. The `<X>` is the generation identifier of the alias - please make sure that you have the same alias generation in all realms.

Its a wise idea to also put the matching certificate aside, even if that is not necessary as the certs are read from the database.

Once you have create key and certificate, just import and link the **certificate** using the command (sample assumes CA Signer Generation 1 in realm "democa"):

```bash
openxpkiadm certificate import --realm democa --token certsign --gen 1 \
    --file democa/ca-signer-1.crt
```

