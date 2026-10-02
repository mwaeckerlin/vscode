# Docker Image for Visual Studio Code Server

Visual Studio Code in the browser (code-server), with a docker daemon of its own inside the container. Published for `linux/amd64` and `linux/arm64`.

There is no default password: set one first, in a file `.env` beside `docker-compose.yaml` (git ignores it) or in the environment:

```bash
$ echo "PASSWORD=$(pwgen -s 24 1)" > .env
```

Start it in the foreground, with the logs on the terminal:

```bash
$ npm start
```

Start it in the background:

```bash
$ npm run start:daemon
```

Stop it:

```bash
$ npm stop
```

Browse to <http://localhost:8080>, enter your password and start with visual studio code.

## Configuration

Variables, one of the two is required; without either the container refuses to start:

- `PASSWORD`: define a password
- `HASHED_PASSWORD`: define a password in hashed format, use `echo -n "a password" | npx argon2-cli -e` to hash a password

Versions before 1.0.1 shipped a `.env` with a published password. Whoever runs an installation that kept it must set a new password.

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

## GitHub SSH Key

Use an SSH key that has access to GitHub only and to none of your servers; create a new key for this purpose where you have none.

The SSH Key must not have a password.

You can add the key file in another way into the container, e.g. by copying it into the volume. Make sure the file is owned by user `somebody` inside the container:

```bash
$ docker compose exec vscode /bin/mkdir /code/.ssh
$ docker compose exec vscode /bin/chmod go= /code/.ssh
$ docker compose cp ~/.ssh/ssh-id-gateway vscode:/code/.ssh/
$ docker compose exec -u root vscode /bin/chown -R somebody /code/.ssh
```

### Docker Swarm Configuration File

To use your ssh key inside the visual studio code environment, namely to checkout from GitHub using SSH, you mount an existing SSH key as configuration, e.g. if you have an SSH key in `~/.ssh/ssh-id-gateway`:

In `docker-compose.yml` include configuration `ssh-key` below `services:` - `vscode:` - `configs`:

```yaml
services:
  vscode:
    configs:
      - source: ssh-key
        target: /code/.ssh/ssh-id-gateway
```

and below `configs`, define the `ssh-key` configuration that points to a SSH key on your host server:

```yaml
configs:
  ssh-key:
    file: ~/.ssh/ssh-id-gateway
```

This configuration only works in docker swarm.

## Development

```bash
$ npm run build
$ npm test
```

`npm test` checks the feature register ([FEATURES.md](FEATURES.md), [TESTS.md](TESTS.md)) and runs `tests/run-e2e.sh`: the refusal without a password, the login with a plain and a hashed password, and the docker daemon inside. The image is built and published by the reusable workflow of [mwaeckerlin/scratch](https://github.com/mwaeckerlin/scratch#publishing-on-docker-hub).

## Sample Production File

In a production environment, you must use `https` so that the password is not sent unencrypted over the network.

Therefore I recommend using `kong` as gateway server: It handles letsencrypt SSL certificate generation and stores the certificates on redis.

See `production.yaml` and `kong.yaml`.

You need a public host name and an e-mail address for letsencrypt. In `kong.yaml` replace every `HOSTNAME` by the public host name (without path and without protocol, e.g. only `example.com`, not `https://example.com/`), then replace `EMAIL` by your e-mail address.

To test the configuration, replace `HOSTNAME` by your public host name and run:

```bash
$ curl http://localhost:8001/acme -d host=HOSTNAME -d test_http_challenge_flow=true
```

To get a certificate, replace `HOSTNAME` by your public host name and run:

```bash
$ curl http://localhost:8001/acme -d host=HOSTNAME
```
