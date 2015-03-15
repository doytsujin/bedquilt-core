# Bedquilt

![Bedquilt](./resources/bedquilt_logo_tile.png)

A JSON store on PostgreSQL.


# Warning

Bedquilt is currently worse-than-alpha quality and should not be used in production,
or anywhere else for that matter. If Bedquilt kills your database, just imagine me
whispering "told you so" and think hard about how you got yourself into this
mess.


# Installation

Run the following to build the extension and install it to the local database:

```bash
make install
```

Run this to build to a zip file:

```bash
make dist
```

Then, on the postgres server:

```sql
CREATE EXTENSION bedquilt;
```


# Tests

Run `bin/run-tests.sh` to run the test suite. Requires a `bedquilt_test` database
that the current user owns.
