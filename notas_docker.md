# Docker Notes

## Key Concepts
- **Image**: an immutable artifact that contains the filesystem and instructions to create a container.
- **Container**: a running instance of an image.
- **Dockerfile**: the instruction file used by Docker to build an image.
- **Build context**: the directory sent to the Docker daemon during build. Usually the directory where the `Dockerfile` is located.

## Basic Commands

### 1. Build an image
`docker build -t my-app .`
- `-t my-app`: assigns a tag (name) to the image.
- `.`: uses the current directory as the build context.

### 2. List local images
`docker images`
- lists images stored on the Docker host.

### 3. Run a container
`docker run -d -p 8080:80 --name my-site my-app`
- `-d`: runs the container in detached mode (background).
- `-p 8080:80`: maps container port 80 to host port 8080.
- `--name my-site`: assigns a friendly name to the container.
- `my-app`: image used to create the container.

### 4. List running containers
`docker ps`
- shows active containers.
- `docker ps -a`: shows all containers, including stopped ones.

### 5. Stop a container
`docker stop my-site`
- sends a signal to gracefully stop the container.

### 6. Remove a container
`docker rm my-site`
- deletes a stopped container to free resources.

### 7. Show logs
`docker logs my-site`
- displays container output for debugging.
- `docker logs -f my-site`: follows logs in real time.

### 8. Access a container shell
`docker exec -it my-site /bin/bash`
- `-it`: attaches an interactive terminal to the container.
- allows running commands inside a running container.

### 9. Remove an image
`docker rmi my-app`
- deletes the local image if no containers are using it.

## Useful Tips
- Use `COPY` in the `Dockerfile` instead of `cp /path/on/host` to move files into the image.
- For production, keep images small and avoid unnecessary files in the build context.
- Only expose needed ports with `EXPOSE` and map them with `-p` when running.
- If you need to rebuild an image after a change, use `docker build --no-cache -t my-app .` to force a fresh build.

## Quick Workflow Example
1. Update the `Dockerfile`.
2. `docker build -t my-apache .`
3. `docker run -d -p 8080:80 --name my-apache-container my-apache`
4. `docker ps`
5. `curl http://localhost:8080` or open it in a browser.
6. `docker stop my-apache-container`
7. `docker rm my-apache-container`

## Note
Docker uses the current directory as the context when running `docker build .`, so avoid including large unnecessary files in the same directory as the `Dockerfile`.

