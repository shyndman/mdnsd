# mdnsd - mDNS Repeater for Docker

**mdnsd** makes it easy to bridge mDNS packets between Docker networks and
LAN-facing network interfaces. Pre-built containers are available on [Docker Hub](https://hub.docker.com/r/kjkent/mdnsd) and [GitHub Container Registry](https://github.com/shyndman/mdnsd/pkgs/container/mdnsd).

mdnsd is a Python wrapper around the powerful [mdns-repeater](https://github.com/geekman/mdns-repeater) by [**geekman**](https://github.com/geekman). mdnsd provides a convenient abstraction for resolving Docker network names to host interfaces, and passing these to `mdns-repeater` for ...repeating. For advanced use cases, it's possible to pass command-line arguments directly to `mdns-repeater`.

## Usage

### Docker CLI

```Shell
docker run -d \
  --name mdnsd \
  -e MDNSD_HOST_INTERFACES='[if_names]' \
  -e MDNSD_DOCKER_NETWORKS='[net_names]' \
  -v '/var/run/docker.sock:/var/run/docker.sock:ro'
  kjkent/mdnsd
```

### Docker Compose

#### Using Docker Hub

```yaml
services:
  mdnsd:
    container_name: mdnsd
    environment:
      MDNSD_DOCKER_NETWORKS: '[net_names]'
      MDNSD_HOST_INTERFACES: '[if_names]'
    image: kjkent/mdnsd
    network_mode: host
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

#### Using GitHub Container Registry

```yaml
services:
  mdnsd:
    container_name: mdnsd
    environment:
      MDNSD_DOCKER_NETWORKS: '[net_names]'
      MDNSD_HOST_INTERFACES: '[if_names]'
    image: ghcr.io/shyndman/mdnsd:latest
    network_mode: host
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

## Advice

- `MDNSD_HOST_INTERFACES` and `MDNSD_DOCKER_NETWORKS` are space-delimited lists.
- Host interfaces can be found using a CLI tool such as `ip link`, and can look like `wlan0`, `eth0`, `enp6s0`, etc...
- By default, Docker names its bridge networks like `docker0`, but it's strongly recommended to set static names for the network(s) you wish to use with mdnsd. This precludes any issues with Docker unexpectedly using a different network name.
- Currently, mdnsd only supports resolving **Docker bridge networks**, though other types like macvlan will likely be added later.
- A maximum of five total interfaces (host interfaces + Docker networks) is supported.

> [!CAUTION]
> Mounting the Docker socket (`/var/run/docker.sock`) to a container (even as read-only!) essentially gives it root access to your machine. Be aware of the security considerations this involves, and consider using a socket proxy.
>
> mdnsd uses the Docker socket to resolve Docker network names to host interface names. Review the file `src/python/entrypoint.py` for the implementation details.
>
> If you are using mdnsd to repeat traffic across host interfaces only, you do not need to mount the socket and can remove it from the configuration. In this scenario, ensure `MDNSD_DOCKER_NETWORKS` is not defined, otherwise the container will error-out.

### Building locally

The provided `build.yaml`, by default, builds an image tagged as `kjkent/mdnsd:local`. Similarly, the sample `docker-compose.yaml` looks for an image named `kjkent/mdnsd:latest` (`:latest` being the default tag). These files are found in `src/docker`; edit them to fit your needs.

These commands are given as a loose guide; everybody's requirements and environments differ. If you're in doubt, use a prebuilt image as demonstrated above.

```Shell
# Clone the repo
git clone --recursive https://github.com/kjkent/mdnsd.git

# Build the container
docker compose -f mdnsd/src/docker/build.yaml build

# Launch the service
docker compose up -d

# Watch it fly
docker compose logs --follow
```

### Direct access to `mdns-repeater`

`mdns-repeater` accepts the following additional command-line arguments:

```text
-b  blacklist subnet (eg. 192.168.1.1/24)
-w  whitelist subnet (eg. 192.168.1.1/24)
```

These can be used by passing them as commands through Docker. With Docker Compose, this is accomplished using the `command` key. For the Docker CLI, just append the args to the end of the `docker run` command.

## Acknowledgements

- [geekman/mdns-repeater](https://github.com/geekman/mdns-repeater): mdnsd is a simple wrapper around this powerful utility.

- [monstrenyatko/docker-mdns-repeater](https://github.com/monstrenyatko/docker-mdns-repeater) - A similar project and the inspiration for mdnsd.
