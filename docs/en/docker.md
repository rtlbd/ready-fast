# Docker

🌐 **English** | [বাংলা](../bn/docker.md)

[← Documentation home](README.md)

Docker runs applications in containers: small, isolated packages that contain a program together with everything it needs. A website, a database or a whole application stack can then be started with one command and removed again without leaving traces on the server.

This guide shows how to install Docker with ready-fast, run your first containers, and avoid the two mistakes that hurt beginners most. The exact behaviour of the installation script is documented in [docker-install](scripts/docker-install.md).

## Install Docker

Preview the installation, then run it:

```bash
sudo ready-fast run docker-install --dry-run
sudo ready-fast run docker-install
```

- Root permission: required.
- What is installed: Docker Engine, the `docker` command, containerd, Buildx and the Compose plugin, from Docker's official apt repository.
- Risk: a new system service and a new software source are added. Nothing existing is removed. If old Docker packages such as `docker.io` are present, the script stops and tells you.

## Run your first container

```bash
sudo docker run --rm hello-world
```

- `docker run` starts a container from an image. The image `hello-world` is downloaded automatically the first time.
- `--rm` removes the container again when it has finished.

Expected output (shortened):

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

## A real example: a web server

Start the nginx web server in the background, reachable only from the server itself:

```bash
sudo docker run -d --name web -p 127.0.0.1:8080:80 nginx
```

- `-d` runs the container in the background.
- `--name web` gives it a name, so that you can refer to it later.
- `-p 127.0.0.1:8080:80` connects port 8080 of the server, on the local address only, to port 80 inside the container.

Check that it answers:

```bash
curl -I http://127.0.0.1:8080
```

The first line of the answer should be `HTTP/1.1 200 OK`.

See what is running, then stop and remove the container:

```bash
sudo docker ps
sudo docker stop web
sudo docker rm web
```

## Use Docker without sudo

By default only root may talk to Docker. To let the user `deploy` run `docker` directly:

```bash
sudo ready-fast run docker-install --user deploy
```

The user must log out and log in again. This works even when Docker is already installed; the script then only adds the user to the group.

**Warning:** members of the `docker` group can become root on the server, because a container may mount and change any file of the host. Give this right only to people who may also use `sudo`.

## Docker Compose

Compose starts several containers that belong together from one file. It is installed as a plugin, so the command is `docker compose` with a space, not the older `docker-compose`:

```bash
docker compose version
```

## Docker and the firewall

This is the most important thing to understand about Docker on a server.

Docker manages its own firewall rules. A port that you publish with `-p 8080:80` is reachable from the whole internet, **even when UFW is active and has no rule for port 8080**. Many people believe UFW protects them and expose databases by accident.

- For services that only the server itself or a reverse proxy on the same server should reach, publish on the local address: `-p 127.0.0.1:8080:80`.
- Publish on all addresses (`-p 80:80`) only for services that really must be public.
- After starting containers, check what is open with `sudo ready-fast run network-info` and look at the "Listening ports" section.

More about UFW is in [Firewall](firewall.md).

## Update Docker

Docker is updated through apt, like every other package:

```bash
sudo apt-get update
sudo apt-get install --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Running containers are stopped while the Docker service restarts during the update. Plan updates for a quiet time.

## Keep an eye on disk space

Images, stopped containers and build cache use disk space in `/var/lib/docker`.

```bash
sudo docker system df
```

This shows how much space Docker uses. To free space:

```bash
sudo docker system prune
```

**Warning:** this deletes all stopped containers, unused networks, dangling images and the build cache. It asks for confirmation first. Volumes are not deleted.

## Remove Docker

Follow the "Rollback instructions" section of [docker-install](scripts/docker-install.md). Remember that deleting `/var/lib/docker` destroys all images, containers and volumes.

## Common problems

| Problem | Solution |
| --- | --- |
| `permission denied while trying to connect to the Docker daemon socket` | Use `sudo`, or add your user to the `docker` group as shown above and log in again. |
| `Cannot connect to the Docker daemon` | The service is not running. Check it with `sudo systemctl status docker` and start it with `sudo systemctl start docker`. |
| `port is already allocated` | Another program or container already uses this port. Choose another port number on the left side of `-p`. |
| Downloading images is very slow or fails | Check the connection with `ready-fast run network-info --check`. |

More solutions are in the troubleshooting section of [docker-install](scripts/docker-install.md) and in [Troubleshooting](troubleshooting.md).
