.PHONY: all build bash run test
NAME=juliawebcon
AUTHOR=keijsers
VERSION=$(shell date +'%Y%m%d.0')
FULLDOCKERNAME=$(AUTHOR)/$(NAME):$(VERSION)
UNAME = $(shell uname -m)

all: build

build:
	@echo "building for $(UNAME)"
	ifeq ($(UNAME),arm64)
		cp Dockerfile_M1 Dockerfile
		docker build --platform linux/arm64 --no-cache=true -t $(FULLDOCKERNAME) .
		docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest
	endif

	ifeq ($(UNAME),x86_64)
		cp Dockerfile_X86 Dockerfile
		docker build --platform linux/amd64 --no-cache=true -t $(FULLDOCKERNAME) .
		docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest
	endif

bash:
	docker run -it -p 80:80 --entrypoint /bin/bash $(AUTHOR)/$(NAME):latest

run:
	docker run -d -p 80:80 $(AUTHOR)/$(NAME):latest

test:
	curl http://localhost:80
	@echo $?
