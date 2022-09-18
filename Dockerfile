FROM julia:latest
WORKDIR /app



RUN ls /app

COPY ./work/Julia.tgz /app/Julia.tar.gz
RUN tar xzvf /app/Julia.tar.gz && \
    rm -rf /app/Julia.tar.gz

COPY app.jl /app/app.jl
ENV PATH $PATH:/app/Volumes/Julia-1.8.1/Julia-1.8.app/Contents/Resources/julia/bin
EXPOSE 80
#ENTRYPOINT ["/app/Volumes/Julia-1.8.1/Julia-1.8.app/Contents/Resources/julia/bin/julia"]
ENTRYPOINT ["julia"]
CMD ["/app/app.jl"]
