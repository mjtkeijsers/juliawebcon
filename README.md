# juliawebcon

Combining Docker, Julia, webserver and local storage in
a minimalistic hello world approach.
Data can also persist over runs by using volumes.

Build this container with:

```
make build
```

Run this container with:

```
make run
```

if desired can get into the container with:

```
make bash
```

To persist the data file over container sessions, create a 'volume':

```
docker volume create myvolumename
```

Then start the container by binding the `/app` dir in container to
`myvolumename` volume:

```
docker run -v myvolumename:/app -p 80:80 juliacon
```

When running the server can be accessed via browser,
on `http://localhost:80`, on each page refresh a timestamp
is written to the web page and into a txt file inside the container.

The minimalistic julia program writes the time of request received into a file.
You can verify volumes work by looking in the container over runs and see that
file being appended all the time.

Also notice that when starting 2 containers on the same volume the file
is 'shared', both instances write to to the same file.

With Regards,

Marc
