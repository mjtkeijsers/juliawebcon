# JuliaWebCon

A small Dockerized Julia 1.13.2 web server with a single text box. The page echoes text as you type; pressing Enter appends it to `data/serverlocalstorage.txt`.

## Run

Build and start the container:

```bash
make build
make run
```

Open [http://localhost:80](http://localhost:80). The `make run` command mounts a named Docker volume at `/app/data`, so submitted text persists when the container is removed and recreated.

To run the image manually with a named volume:

```bash
docker volume create juliawebcon_data
docker run -d -p 80:80 -v juliawebcon_data:/app/data --name juliawebcon keijsers/juliawebcon:latest
```

## Useful commands

- `make build` builds the Docker image for the current architecture.
- `make run` starts the server with persistent storage.
- `make stop` stops the most recently created running project container.
- `make bash` opens a shell inside the image.
- `make test` requests the local server.

## Project files

- `app.jl` - the text echo server and append-to-volume logic
- `Dockerfile_M1` and `Dockerfile_X86` - Docker image definitions
- `Makefile` - convenience commands for Docker workflows
- `juliapod.yml` - project metadata for JuliaPod tooling

## License

This project is distributed under the MIT License. See [LICENSE](LICENSE).
