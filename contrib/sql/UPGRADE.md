# SQL Schema Maintenance

To allow us to add new features without breaking existing installations
we introdcue a database schema version indicator with release v3.26.

This indicator is stored in the datapool tables with `namespace = config`
and `datapool_key = dbschema`, with the value holding the version number
of the schema as integer.

This file lists the additions to the schema to allow users to upgrade.

## Adding schema information the first time

Set the version indicator to `2` if you have the full schema shipped with
release v3.14 or later, otherwise set `1`.

```sql
INSERT INTO datapool (`pki_realm`,`namespace`,`datapool_key`,`datapool_value`)
VALUES ('','config','dbschema','2');
```

## Upgrades for schema version v3

### Update schema indicator
```sql
UPDATE datapool SET datapool_value = 3
    WHERE `namespace` = 'config' and `datapool_key` = 'dbschema';
```