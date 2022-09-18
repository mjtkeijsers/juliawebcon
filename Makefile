.PHONY: all build bash run test
NAME=juliawebcon
AUTHOR=keijsers
VERSION=$(shell date +'%Y%m%d.0')
FULLDOCKERNAME=$(AUTHOR)/$(NAME):$(VERSION)
UNAME = $(shell uname -p)

all: build

build:
	  echo "building"
		echo $(PROCESSOR_ARCHITECTURE)
		echo $(OS)
		echo $(AUTHOR)
		echo $(UNAME)
		echo $(FULLDOCKERNAME)
    ifeq ($(UNAME),arm)
				mkdir ./work
				curl https://julialang-s3.julialang.org/bin/mac/aarch64/1.8/julia-1.8.1-macaarch64.dmg -o ./work/julia.dmg
				hdiutil attach ./work/julia.dmg

				tar -czvf ./work/Julia.tgz /Volumes/Julia-1.8.1/*
	    	cp Dockerfile_M1 Dockerfile

				docker build --no-cache=true -t $(FULLDOCKERNAME) .
				@# and only now tag the built image as the "latest"
				docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest

				rm -rf work
				#hdiutil detach Julia-1.8.1 -force
        endif

    ifeq ($(UNAME),x86)
		    cp Dockerfile_X86 Dockerfile
				docker build --no-cache=true -t $(FULLDOCKERNAME) .
				@# and only now tag the built image as the "latest"
				docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest
        endif

bash:
	docker run -it -p 80:80 --entrypoint /bin/bash $(AUTHOR)/$(NAME):latest

run:
	docker run -d -p 80:80 $(AUTHOR)/$(NAME):latest

test:
	curl http://localhost:80
	@echo $?
