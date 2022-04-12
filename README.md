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

In `docker-compose.yml` add below `services:` - `vscode:` the tag `user: "100:xxx"`, where you replace `xxx` by the group id of `/var/run/docker.sock` in the *host* system, on my system, this is `999`, the id of group `docker`:

```bash
$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Mär  8 21:31 /var/run/docker.sock
$ getent group docker | cut -d: -f3
999
```

```yaml
services:
  vscode:
    user: "100:999"
```

Then add below `services:` - `vscode:` - `volumes:` a bind mount to `/var/run/docker.pid`:

```yaml
services:
  vscode:
    volumes:
      - type: bind
        source: /var/run/docker.sock
        target: /var/run/docker.sock
```

## Login to Github with SSH Key

Be careful when you use this configuration. Make shure, the SSH key does only access GitHub and does not access any of your server. Otherwise create a new SSH key, only for this purpose.

The SSH Key must not have a password.

You can add the key file in another way into `docker-compose`, e.g. by copying it into the volume.
Make sure the file is owned by user `somebody` insde the container:

    docker exec vscode_vscode_1 /bin/mkdir /data/.ssh
    docker exec vscode_vscode_1 /bin/chmod go= /data/.ssh
    docker cp ~/.ssh/id_ed25519 vscode_vscode_1:/data/.ssh/id_ed25519
    docker exec -u root vscode_vscode_1 /bin/chown somebody /data/.ssh/id_ed25519

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