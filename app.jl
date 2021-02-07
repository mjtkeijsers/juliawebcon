import Pkg;
Pkg.add("HTTP")
Pkg.add("Dates")

using HTTP, Sockets, Dates

println("Starting my server ...")

#Write to a file, this file is stored in the dir where
# the julia program runs

#in case program runs in container data is stored inside container
# at /app dir as specified WORKDIR in Dockerfile

#To persist the data file over container sessions:
# create a 'volume' : docker volume create myvolumename
#
#Then start the container by binding the /app dir in container to
# myvolumename: docker run -v myvolumename:/app -p 80:80 juliacon
open("serverlocalstorage.txt", "a") do io
       write(io, "Start the server\n")
   end;

HTTP.listen("0.0.0.0", 80) do http
    println("Caught the next request ..." )

    d_now = Dates.format(now(), "HH:MM:SS")

    #if desired can see into the container via
    # docker exec -t -i mycontainer_id /bin/bash
    open("serverlocalstorage.txt", "a") do io
           write(io, "Serving a request\n")
           write(io, d_now)
           write(io, "----\n")
    end;

    HTTP.setheader(http, "Content-Type" => "text/html")
    write(http, "MKEJ Hello World of VCP<BR>")
    write(http, string(d_now))
    return
end
