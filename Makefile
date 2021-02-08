.PHONY: all build bash run test
NAME=juliawebcon
AUTHOR=belooussov
VERSION=$(shell date +'%Y%m%d.0')
FULLDOCKERNAME=$(AUTHOR)/$(NAME):$(VERSION)

all: build

build:
	docker build --no-cache=true -t $(FULLDOCKERNAME) .
	@# and only now tag the built image as the "latest"
	docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest

bash:
	docker run -it -p 80:80 --entrypoint /bin/bash $(AUTHOR)/$(NAME):latest

run:
	docker run -d -p 80:80 $(AUTHOR)/$(NAME):latest

test:
	curl http://localhost:80
	@echo $?
