# Ansible Mastodon setup

This playbook deploys Mastodon using Docker Compose, with Ansible managing the
host, reverse proxy, configuration files, data directories, migration from the
previous native install layout, and Compose reconciliation.

In order to fetch dependencies for Ansible you need to run (also after updating the repository):

```shell
make roles
```

Create an inventory file (`inventory.ini`):

```ini
[server]
159.69.3.194
```

Then you can then run the playbook:

```shell
ansible-playbook -u root -i inventory.ini install.yml
```

## Extra variables

You will most likely needs some additional variables set. You can do this with:

```shell
ansible-playbook -u root -i inventory.ini --extra-vars=@extra-vars.yaml install.yml
```

And, have a file like:

~~~yml
---
mastodon_domain: dentrassi.de
mastodon_public_hostname: mastodon.dentrassi.de

mastodon_email_sender: mastodon@dentrassi.de
mastodon_smtp_host: foo.bar.de
mastodon_smtp_port: 587
mastodon_smtp_password: bar-foo 

letsencrypt_email: my@domain.org

# generate with: docker run --rm -ti ghcr.io/mastodon/mastodon:v4.6.2 bundle exec rake secret
secret_key_base: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
# generate with: docker run --rm -ti ghcr.io/mastodon/mastodon:v4.6.2 bundle exec rake secret
otp_secret: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
# generate both with: docker run --rm -ti ghcr.io/mastodon/mastodon:v4.6.2 bundle exec rake mastodon:webpush:generate_vapid_key
vapid_private_key: ...
vapid_public_key: ...

# Optional. If empty, the PostgreSQL container is configured with trust auth
# inside the private Compose network.
mastodon_postgres_password: ...

# Deploy Redis alongside Mastodon in Docker Compose. Defaults to true.
mastodon_redis_enabled: true
~~~

## Native to Docker migration

When the playbook sees an existing native checkout at `/home/mastodon/live/.git`
and no marker at `/opt/mastodon/.native-to-docker-migrated`, it performs a
one-time migration:

* stop and disable the native `mastodon-web`, `mastodon-streaming`, and
  `mastodon-sidekiq` services
* dump the native `mastodon` PostgreSQL database
* copy `/home/mastodon/live/public/system` to `/opt/mastodon/public/system`
* start the Docker PostgreSQL and Redis services
* restore the database into Docker PostgreSQL
* run Mastodon database migrations
* write `/opt/mastodon/.native-to-docker-migrated`

After that marker exists, rerunning the playbook skips the migration and only
reconciles the Docker Compose stack.

If Docker PostgreSQL data already exists but the marker is missing, the playbook
stops with an error instead of importing the native database again. Inspect
`/opt/mastodon` and either create the marker after verification, remove the
partial Docker state, or rerun with:

```yaml
mastodon_force_native_to_docker_migration: true
```

By default, every migration attempt creates a fresh native database dump before
restoring it into Docker PostgreSQL. To explicitly reuse
`/opt/mastodon/backups/mastodon-native.dump` during a retry, set:

```yaml
mastodon_reuse_native_database_dump: true
```

After the Docker deployment is verified, the native cron jobs and systemd unit
files can be removed with:

```yaml
mastodon_cleanup_native_after_migration: true
```

This cleanup does not delete `/home/mastodon/live` or the old PostgreSQL data.

## Wrapper repository

It might make sense to use this repository, which contains only public information, as a
git submodule, so that you can store private data into a private repository.

Then run the playbook like this:

```shell
ansible-playbook -u root -i ../inventory.ini --extra-vars=@../extra-vars.yaml install.yml
```

Or, from the root of the wrapper repository:
```shell
ansible-playbook -u root -i inventory.ini --extra-vars=@extra-vars.yaml ansible-mastodon-setup/install.yml
```

## Create your first user

Create a new user through the web-console, and then make it admin using:

```shell
cd /opt/mastodon
docker compose run --rm web bin/tootctl accounts create \
  alice \
  --email alice@example.com \
  --confirmed \
  --role admin
```

## Performing an upgrade

  * Switch to the new version in `roles/mastodon/defaults/main.yml`
  * And then run the install playbook again

    ```shell
    ansible-playbook -u root -i inventory.ini --extra-vars=@extra-vars.yaml ansible-mastodon-setup/install.yml
    ```

    Or:

    ```shell
    ansible-playbook -u root -i ../inventory.ini --extra-vars=@../extra-vars.yaml install.yml
    ```

The playbook pulls the configured images, runs database migrations, and starts
the Compose stack.
