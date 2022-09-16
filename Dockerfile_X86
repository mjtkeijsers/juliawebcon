FROM julia:latest
WORKDIR /app
RUN curl https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.3-linux-x86_64.tar.gz -o /app/julia.tar.gz && \
    tar xzvf /app/julia.tar.gz && \
    rm -rf /app/julia.tar.gz
COPY app.jl /app/app.jl
ENV PATH $PATH:/app/julia-1.5.3/bin
EXPOSE 80
ENTRYPOINT ["/app/julia-1.5.3/bin/julia"]
CMD ["/app/app.jl"]
