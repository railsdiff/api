# RailsDiff API

This app serves the data for [railsdiff.org](http://railsdiff.org). It
does so by reporting its known versions at the `/versions` path, and
with diffs at the `/:source/:target` path. And, those diffs are
generated on the fly from the generated Rails apps included in this app.

## Generating files

This project makes extensive use of Rake. The default task generates all
the missing generated Rails apps:

```sh
rake
```

But, each generated Rails app can be independently [re]generated:

```sh
rake generated/v3.0.0/v4.0.0.beta1
```
