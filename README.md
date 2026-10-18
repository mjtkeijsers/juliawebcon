# JuliaWebCon

A small Dockerized Julia web server with an animated Conway's Game of Life simulation and local file storage.

The application serves a centered, interactive Game of Life board, writes a timestamp to a file each time a request is received, and can persist that data across container runs by using Docker volumes.

## What this project does

- Starts a Julia HTTP server on port 80
- Responds with a centered, animated Conway's Game of Life board
- Lets visitors pause, restart, and toggle cells on the board
- Copies entered text to an adjacent display with the time it was submitted
- Logs timestamps to `serverlocalstorage.txt` in `/app`
- Works in Docker on both x86 and Apple Silicon environments
- Supports persisting data with Docker volumes

## Architecture

Browser
  -> Docker container
    -> Julia HTTP server (`app.jl`)
      -> writes to `serverlocalstorage.txt`

The board evolves in the browser using Conway's rules. Each page refresh also triggers a request, and the server appends its timestamp to the log file.

## Prerequisites

Before running the project, make sure you have:

- Docker installed and running
- `make` available on your system
- Network access to download the Julia runtime image

## Quick start

Build the container:

```bash
make build
```

Run the container:

```bash
make run
```

Open a browser and visit:

```text
http://localhost:80
```

You should see the animated Game of Life board. The server appends a log entry to `serverlocalstorage.txt` on each request.

## Useful commands

Open an interactive shell in the running container:

```bash
make bash
```

Stop the most recently created running container for this project:

```bash
make stop
```

Check the response manually from the terminal:

```bash
curl http://localhost:80
```

## Persisting data across container runs

The application writes data to `/app/serverlocalstorage.txt`. By default, that file is stored inside the container filesystem, so it may disappear when the container is removed.

To persist it across runs, create a Docker volume:

```bash
docker volume create juliawebcon_data
```

Then run the container with the volume mounted to `/app`:

```bash
docker run -d -p 80:80 -v juliawebcon_data:/app --name juliawebcon keijsers/juliawebcon:latest
```

This keeps the file on the host machine even if the container is stopped or recreated.

## About the Makefile

The project includes a small `Makefile` to simplify Docker workflows:

- `make build` builds the Docker image
- `make run` starts the container in the background
- `make stop` stops the most recently created running project container
- `make bash` opens a shell inside the container
- `make test` curls the local HTTP endpoint

## Project files

- `app.jl` - the Julia web server and file-writing logic
- `Dockerfile_X86` - Docker image definition for x86_64 systems
- `Dockerfile_M1` - Docker image definition for Apple Silicon systems
- `Makefile` - convenience commands for building and running the project
- `juliapod.yml` - project metadata for JuliaPod tooling

## Notes

- This project is intentionally minimal and educational.
- The example demonstrates how Docker containers can be used for simple local persistence and web services.
- If you launch multiple containers using the same Docker volume, they will share the same log file and write to it concurrently.

## License

This project is distributed under the MIT License. See `LICENSE` for details.

With regards,

Marc
