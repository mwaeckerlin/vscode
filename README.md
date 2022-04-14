# Docker Image for Visual Studio Code Server

Run `docker-compose up`, browse to [http://localhost:8080], enter password: `change-me` and start with visual studio code.

## Configuration

Variables:

- `PASSWORD`: define a password - you really should overwrite the default: `change-me`

Volumes:

- `/data`: user home, use it for your projects, configuration is in `/data/.config`

SSH-Keys:

- `/data/.ssh`: copy SSH keys into this path

## Use Docker

A local docker instance is integrated into the image. 

Note: Because of docker in docker, the image must be started with option `--privileged`. Without this option, docker will not work. Everything else should be fine.

Be aware: With `--priviledged` you gain access to upper layer operation system.

We don't bind-mount `/var/run/docker.sock`, because that would give you access to all docker images in the host system, including your own. That's why we start an own docker instance inside the image.

## Login to Github with SSH Key

Be careful when you use this configuration. Make shure, the SSH key does only access GitHub and does not access any of your server. Otherwise create a new SSH key, only for this purpose.

The SSH Key must not have a password.

You can add the key file in another way into the container, e.g. by copying it into the volume.
Make sure the file is owned by user `somebody` insde the container:

    docker-compose exec vscode /bin/mkdir /data/.ssh
    docker-compose exec vscode /bin/chmod go= /data/.ssh
    docker-compose cp ~/.ssh/id* vscode:/data/.ssh/
    docker-compose exec -u root vscode /bin/chown -R somebody /data/.ssh

### Docker Swarm Configuration File

To use your ssh key inside the visual studio code environment, namely to checkout from GitHub using SSH, you mount an existing SSH key as configuration, e.g. if you have an SSH key in `~/.ssh/id_ed25519`:

In `docker-compose.yml` include configuration `ssh-key` below `services:` - `vscode:` - `configs`:

```yaml
services:
  vscode:
    configs:
      - source: ssh-key
        target: /data/.ssh/id_ed25519
```

and below `configs`, define the `ssh-key` configuration that points to a SSH key on your host server:

```yaml
configs:
  ssh-key:
    file: ~/.ssh/id_ed25519
```

This configuration only works in docker swarm. 