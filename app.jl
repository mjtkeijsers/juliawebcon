import Pkg;Pkg.add("HTTP")

using HTTP, Sockets

println("Starting my server ...")

HTTP.listen("127.0.0.1", 8081) do http
    println("Caught a request ..." )

    HTTP.setheader(http, "Content-Type" => "text/html")
    write(http, "MKEJ Hello World of VCP<BR>")
    return
end
