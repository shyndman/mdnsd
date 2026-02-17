# mdnsd - mDNS Repeater for Docker

**mdnsd** makes it easy to bridge mDNS packets between Docker networks and
LAN-facing network interfaces. Pre-built containers are available on [GitHub Container Registry](https://github.com/shyndman/mdnsd/pkgs/container/mdnsd).

mdnsd is a Python wrapper around the powerful [mdns-repeater](https://github.com/geekman/mdns-repeater) by [**geekman**](https://github.com/geekman). mdnsd provides a convenient abstraction for resolving Docker network names to host interfaces, and passing these to `mdns-repeater` for ...repeating. For advanced use cases, it's possible to pass command-line arguments directly to `mdns-repeater`.

## Usage

### Docker CLI

```Shell
docker run -d \
  --name mdnsd \
  --network host \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --cap-add NET_RAW \
  -e MDNSD_HOST_INTERFACES='[if_names]' \
  -e MDNSD_DOCKER_NETWORKS='[net_names]' \
  --volume '/var/run/docker.sock:/var/run/docker.sock:ro' \
  ghcr.io/shyndman/mdnsd:v0.0.1
```

### Docker Compose

```yaml
services:
  mdnsd:
    container_name: mdnsd
    environment:
      MDNSD_DOCKER_NETWORKS: '[net_names]'
      MDNSD_HOST_INTERFACES: '[if_names]'
    image: ghcr.io/shyndman/mdnsd:v0.0.1
    network_mode: host
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_RAW
```

## Advice

- `MDNSD_HOST_INTERFACES` and `MDNSD_DOCKER_NETWORKS` are space-delimited lists.
- Host interfaces can be found using a CLI tool such as `ip link`, and can look like `wlan0`, `eth0`, `enp6s0`, etc...
- By default, Docker names its bridge networks like `docker0`, but it's strongly recommended to set static names for the network(s) you wish to use with mdnsd. This precludes any issues with Docker unexpectedly using a different network name.
- Currently, mdnsd only supports resolving **Docker bridge networks**, though other types like macvlan will likely be added later.
- A maximum of five total interfaces (host interfaces + Docker networks) is supported.

### Security Hardening

The examples include several security hardening options:
- `read_only: true` / `--read-only`: Makes the container filesystem read-only, preventing modifications at runtime
- `security_opt: no-new-privileges:true` / `--security-opt no-new-privileges:true`: Prevents the container from gaining additional privileges
- `cap_drop: ALL` / `--cap-drop ALL`: Drops all Linux capabilities
- `cap_add: NET_RAW` / `--cap-add NET_RAW`: Adds only the NET_RAW capability required for mdns-repeater to function

These options ensure the container runs with minimal privileges. The mdns-repeater binary has been configured with setcap (see `src/docker/Dockerfile`) to allow it to run as a non-root user while still being able to send raw packets.

> [!CAUTION]
> Mounting the Docker socket (`/var/run/docker.sock`) to a container (even as read-only!) essentially gives it root access to your machine. Be aware of the security considerations this involves, and consider using a socket proxy.
>
> mdnsd uses the Docker socket to resolve Docker network names to host interface names. Review the file `src/python/entrypoint.py` for the implementation details.
>
> If you are using mdnsd to repeat traffic across host interfaces only, you do not need to mount the socket and can remove it from the configuration. In this scenario, ensure `MDNSD_DOCKER_NETWORKS` is not defined, otherwise the container will error-out.

### Building locally

To build the container locally, use the provided Dockerfile:

```Shell
# Clone the repo
git clone --recursive https://github.com/shyndman/mdnsd.git
cd mdnsd

# Build the container
docker build -t ghcr.io/shyndman/mdnsd:local -f src/docker/Dockerfile .

# Run using docker-compose.yaml as a template
# (Edit src/docker/docker-compose.yaml to use your local image tag)
docker compose -f src/docker/docker-compose.yaml up -d

# Watch it fly
docker compose -f src/docker/docker-compose.yaml logs --follow
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
