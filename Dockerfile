#Build this container via docker build -t juliacon .

#Run this container via docker run -p 80:80 juliacon

#if desired can see into the container via
# docker exec -t -i mycontainer_id /bin/bash

# Use an official Julia runtime as a parent image
FROM julia:latest

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Apparently the webserved in the julia program relies on wget
#RUN  apt-get update \
#  && apt-get install -y wget \
#  && rm -rf /var/lib/apt/lists/*

# Install julia (arbitrary version choice in the container)
RUN tar -xvf julia-1.5.3-linux-x86_64.tar

# Make port 8081 available to the world outside this container
EXPOSE 80

# Set the path so 'julia' can be found inside the container
ENV PATH="/app/julia-1.5.3/bin:${PATH}"

#And start the little julia 'hello world' webserver
CMD ["julia", "app.jl"]
