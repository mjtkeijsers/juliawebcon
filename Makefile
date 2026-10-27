.PHONY: all build bash run stop test
NAME=juliawebcon
AUTHOR=keijsers
VERSION=$(shell date +'%Y%m%d.0')
FULLDOCKERNAME=$(AUTHOR)/$(NAME):$(VERSION)
UNAME = $(shell uname -m)

ifeq ($(UNAME),arm64)
DOCKERFILE = Dockerfile_M1
PLATFORM = linux/arm64
else ifeq ($(UNAME),x86_64)
DOCKERFILE = Dockerfile_X86
PLATFORM = linux/amd64
endif

all: build

build:
	@echo "building for $(UNAME)"
	@test -n "$(DOCKERFILE)" || { echo "Unsupported architecture: $(UNAME)" >&2; exit 1; }
	docker build --platform $(PLATFORM) --file $(DOCKERFILE) --no-cache=true -t $(FULLDOCKERNAME) .
	docker tag $(FULLDOCKERNAME) $(AUTHOR)/$(NAME):latest

bash:
	docker run --rm -it --entrypoint /bin/bash $(AUTHOR)/$(NAME):latest

run:
	docker run -d -p 80:80 -v $(NAME)_data:/app/data $(AUTHOR)/$(NAME):latest

stop:
	@container_id=$$(docker ps --latest --filter ancestor=$(AUTHOR)/$(NAME):latest --quiet) || exit $$?; \
	if [ -z "$$container_id" ]; then \
		echo "No running $(NAME) container found." >&2; \
		exit 1; \
	fi; \
	docker stop "$$container_id"

test:
	curl http://localhost:80
	@echo $?
