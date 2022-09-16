FROM julia:latest
WORKDIR /app



ls /app

#RUN docker cp /Volumes/Julia-1.8.1/Julia-1.8.app/Contents/Resources/julia/* /app/julia-1.8.1

COPY app.jl /app/app.jl
ENV PATH $PATH:/app/julia-1.8.1/bin
EXPOSE 80
ENTRYPOINT ["/app/julia-1.8.1/bin/julia"]
CMD ["/app/app.jl"]
