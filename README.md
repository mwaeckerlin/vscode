# Docker Image for Visual Studio Code Server

Run `docker-compose up`, browse to [http://localhost:8080], enter password: `change-me` and start with visual studio code.

## Configuration

Variables:

- `PASSWORD`: define a password
- `HASHED_PASSWORD`: define a password in hashed format, use `echo -n "a password" | npx argon2-cli -e` to hash a password

Volumes:

- `/code`: user home, use it for your projects, configuration is in `/code/.config`
- `/docker`: everything related to docker - you may store this permanently, if you want local docker containers to survive a container recreation

SSH-Keys:

- `/code/.ssh`: copy SSH keys into this path

## Use Docker

A local docker instance is integrated into the image. Docker is running rootless.

Note: Because of docker in docker, the image must be started with option `--privileged`. Without this option, docker will not work. Everything else should be fine.

Be aware: With `--privileged` you gain access to upper layer operation system.

We don't bind-mount `/var/run/docker.sock`, because that would give you access to all docker images in the host system, including your own. That's why we start an own docker instance inside the image.

## Login to Github with SSH Key

Be careful when you use this configuration. Make shure, the SSH key does only access GitHub and does not access any of your server. Otherwise create a new SSH key, only for this purpose.

The SSH Key must not have a password.

You can add the key file in another way into the container, e.g. by copying it into the volume. Make sure the file is owned by user `somebody` inside the container:

    docker-compose exec vscode /bin/mkdir /code/.ssh
    docker-compose exec vscode /bin/chmod go= /code/.ssh
    docker-compose cp ~/.ssh/id_ed25519 vscode:/code/.ssh/
    docker-compose exec -u root vscode /bin/chown -R somebody /code/.ssh

### Docker Swarm Configuration File

To use your ssh key inside the visual studio code environment, namely to checkout from GitHub using SSH, you mount an existing SSH key as configuration, e.g. if you have an SSH key in `~/.ssh/id_ed25519`:

In `docker-compose.yml` include configuration `ssh-key` below `services:` - `vscode:` - `configs`:

```yaml
services:
  vscode:
    configs:
      - source: ssh-key
        target: /code/.ssh/id_ed25519
```

and below `configs`, define the `ssh-key` configuration that points to a SSH key on your host server:

```yaml
configs:
  ssh-key:
    file: ~/.ssh/id_ed25519
```

This configuration only works in docker swarm.

# Sample Production File

In a production envionment, you must use `https` so that the password is not sent unencrypted over the network.

Therefore I recommend using `kong` as gateway server: It handles letsencrypt SSL certificate generation and stores the certificates on redis.

See `production.yaml` and `kong.yaml`.

You need a public host name and an E-Mail for letsencrypt. In `kong.yaml` replace the text `HOSTNAME` by the public host name (without path and without protocol, e.g. only `example.com`, not `https://example.com/`). You need to replace this 3 times. Then replace `EMAIL` by your E-Mail.

To get an initial certificate:

To test the configuration, replace `HOSTNAME` by your public host name and run:

```bash
curl http://localhost:8001/acme -d host=HOSTNAME -d test_http_challenge_flow=true
```

To get a certificate, replace `HOSTNAME` by your public host name and run:

```bash
curl http://localhost:8001/acme -d host=HOSTNAME
```