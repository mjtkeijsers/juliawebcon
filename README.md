# juliawebcon
Combining Docker, Julia, webserver and local storage in a minimalistic hello world approach

Data can also persist over runs by using volumes.

Build this container via: docker build -t juliacon .

Run this container via: docker run -p 80:80 juliacon

if desired can see into the container via: docker exec -t -i mycontainer_id /bin/bash

To persist the data file over container sessions, create a 'volume' : docker volume create myvolumename

Then start the container by binding the /app dir in container to myvolumename: docker run -v myvolumename:/app -p 80:80 juliacon

The minimalistic julia program writes the time of request received into a file. You can verify volumes
work by looking in the container over runs and see that file being appended all the time.

Also notice that when starting 2 containers on the same volume the file is 'shared', both instances write to
to the same file.

With Regards,

Marc
