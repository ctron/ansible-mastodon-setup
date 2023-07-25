# Ansible Mastodon setup

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

# generate with: podman run --rm -ti docker.io/tootsuite/mastodon:v3.5.0 bundle exec rake secret
secret_key_base: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
# generate with: podman run --rm -ti docker.io/tootsuite/mastodon:v3.5.0 bundle exec rake secret
otp_secret: 1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
# generate both with: podman run --rm -ti docker.io/tootsuite/mastodon:v3.5.0 bundle exec rake mastodon:webpush:generate_vapid_key 
vapid_private_key: ...
vapid_public_key: ...
~~~

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
su -s /bin/bash - mastodon
cd ~/live
env RAILS_ENV=production bin/tootctl accounts create \
  alice \
  --email alice@example.com \
  --confirmed \
  --role admin
```

## Performing an upgrade

  * Switch to the new version in `roles/mastodon/defaults/main.yml`
  * And then run the ansible update playbook
  
    ```shell
    ansible-playbook -u root -i inventory.ini --extra-vars=@extra-vars.yaml ansible-mastodon-setup/update.yml 
    ```
    
    Or:

    ```shell
    ansible-playbook -u root -i ../inventory.ini --extra-vars=@../extra-vars.yaml update.yml 
    ```