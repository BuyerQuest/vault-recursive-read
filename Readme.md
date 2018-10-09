# Vault Recursive Read

**vault-recursive-read** is a ruby script that will discover all of the subpaths of a given path in vault, then export them to YAML or JSON.

## Requirements

* ruby with bundler
* vault binaries (you should be able to `vault list secret/` from your command line)

## Usage

Clone this repository to your machine:

```shell
git clone https://github.com/BuyerQuest/vault-recursive-read.git
```

Enter the directory and run `bundle install`:

```shell
cd vault-recursive-read/
bundle install
```

Authenticate to your vault server (use what's appropriate for your setup):
```shell
export VAULT_ADDR=https://my.vault.server
vault auth -method=ldap username=my.username
```

Invoke the script (the trailing slash is important):
```shell
./vault-recursive-read.rb -p secret/foo/
```

## Output

Paths that have keys with no data in them will be shown as **skipped**.

Vault entries are written to STDOUT in the specified format, with progress written to STDERR. Redirect the output to a file to save your data:
```shell
./vault-recursive-read.rb -p secret/test/ > secrets.yaml
```

## Example

```console
$ git clone https://github.com/BuyerQuest/vault-recursive-read.git
Cloning into 'vault-recursive-read'...
remote: Counting objects: 13, done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 13 (delta 2), reused 10 (delta 2), pack-reused 0
Unpacking objects: 100% (13/13), done.

$ cd vault-recursive-read/

$ bundle install
Fetching gem metadata from https://rubygems.org/................
Resolving dependencies...
Using OptionParser 0.5.1
Using bundler 1.16.0
Using vault 0.10.1
Bundle complete! 2 Gemfile dependencies, 3 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

$ export VAULT_ADDR=https://redacted.vault.url

$ vault auth -method=ldap username=fake.username
Successfully authenticated! You are now logged in.
#<snip>

$ ./vault-recursive-read.rb -p secret/test/
Reading secret/test/demo/dir1/dir2/path1
Skipped secret/test/uat/newrelic (no data)
---
secret/justin/demo/dir1/dir2/path1:
  :key1: val1
```

## Arguments

Use the `--help` switch:

```console
16:27 $ ./vault-recursive-read.rb --help
Recursive read for paths in vault.

Usage: ./vault-recursive-read.rb [options]
    -p, --path=PATH                  Path in vault to read from, with a trailing slash. E.g. secret/foo/

    -a, --vault-address=VAULT_ADDR   Optional: URL used to access the Vault server. Defaults to the VAULT_ADDR environment variable
    -t, --vault-token=VAULT_TOKEN    Optional: A vault token. Defaults to VAULT_TOKEN environment variable, or reads ~/.vault-token
    -f, --format=FORMAT              Optional: Output data format. Supports YAML & JSON. Defaults to YAML

    -h, --help                       Display this help
    -v, --version                    Display the current script version
```


## See also

[Vault Recursive Delete](https://github.com/BuyerQuest/vault-recursive-delete)
