# Shockwave's Lab — container management
#
# Run `make` or `make help` for usage.

SHELL := /bin/sh

# Allow overriding, e.g. `make DOCKER=docker up`
DOCKER  ?= sudo docker
COMPOSE := $(DOCKER) compose

# Directory containing this Makefile
ROOT := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

# Auto-discover services: directories containing a docker-compose.yml
SERVICES := $(shell cd $(ROOT) && find . -maxdepth 2 -name docker-compose.yml -exec dirname {} \; | sed 's|^\./||' | sort)

# Act on a single service when SERVICE is set, otherwise on all of them
TARGETS := $(if $(SERVICE),$(SERVICE),$(SERVICES))

.DEFAULT_GOAL := help

.PHONY: help list pull up stop down restart ps logs config upgrade prune

help:
	@echo "Shockwave's Lab — container management"
	@echo
	@echo "  make list                  list discovered services"
	@echo "  make pull                  pull latest images"
	@echo "  make up                    start services (detached)"
	@echo "  make stop                  stop services (keep containers)"
	@echo "  make down                  stop and remove containers/networks"
	@echo "  make restart               recreate services (down + up -d)"
	@echo "  make ps                    show service status"
	@echo "  make logs                  show recent logs"
	@echo "  make config                validate/render compose config"
	@echo "  make upgrade               pull then up"
	@echo "  make prune                 remove unused docker images"
	@echo
	@echo "  Append SERVICE=<dir> to affect a single service, e.g.:"
	@echo "    make up SERVICE=gitea"
	@echo "    make logs SERVICE=immich-app"
	@echo "    make upgrade SERVICE=paperless-ngx"
	@echo
	@echo "  Override the docker command with DOCKER= (current: $(DOCKER))"

list:
	@echo "Discovered services:"
	@for s in $(SERVICES); do echo "  $$s"; done

pull:
	@for s in $(TARGETS); do \
		echo "==> pull $$s"; \
		ok=0; \
		for attempt in 1 2 3; do \
			if ( cd $(ROOT)/$$s && $(COMPOSE) pull ); then ok=1; break; fi; \
			echo "    retry $$attempt for $$s..."; sleep 5; \
		done; \
		[ $$ok -eq 1 ] || { echo "!!! pull failed for $$s"; exit 1; }; \
	done

up:
	@for s in $(TARGETS); do \
		echo "==> up $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) up -d ) || { echo "!!! up failed for $$s"; exit 1; }; \
	done

stop:
	@for s in $(TARGETS); do \
		echo "==> stop $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) stop ) || { echo "!!! stop failed for $$s"; exit 1; }; \
	done

down:
	@for s in $(TARGETS); do \
		echo "==> down $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) down ) || { echo "!!! down failed for $$s"; exit 1; }; \
	done

# Full recreate: tear the project down (removes containers/networks) then
# bring it back up detached. This is what CI calls after a service changes, so
# that edits to a docker-compose.yml actually take effect (compose `restart`
# does NOT re-read the compose file).
restart:
	@for s in $(TARGETS); do \
		echo "==> restart $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) down && $(COMPOSE) up -d ) || { echo "!!! restart failed for $$s"; exit 1; }; \
	done

ps:
	@for s in $(TARGETS); do \
		echo "==> $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) ps ) || true; \
	done

logs:
	@if [ -n "$(SERVICE)" ]; then \
		cd $(ROOT)/$(SERVICE) && $(COMPOSE) logs -f; \
	else \
		for s in $(SERVICES); do \
			echo "==> $$s"; \
			( cd $(ROOT)/$$s && $(COMPOSE) logs --tail=50 ) || true; \
		done; \
	fi

config:
	@for s in $(TARGETS); do \
		echo "==> config $$s"; \
		( cd $(ROOT)/$$s && $(COMPOSE) config >/dev/null ) || { echo "!!! invalid config for $$s"; exit 1; }; \
	done
	@echo "All configs valid."

upgrade: pull up

prune:
	$(DOCKER) image prune -f
