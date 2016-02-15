PROJECT_NAME ?= todobackend
ORG_NAME ?= cloudhotspot
REPO_NAME ?= todobackend

# Use these settings to specify a custom Docker registry
DOCKER_REGISTRY ?= docker.io

# WARNING: Set DOCKER_REGISTRY_DISPLAY to empty for Docker Hub
# Otherwise generally set to DOCKER_REGISTRY
DOCKER_REGISTRY_DISPLAY ?= 


# WARNING: Set DOCKER_REGISTRY_AUTH to empty for Docker Hub
# Set DOCKER_REGISTRY_AUTH to auth endpoint for private Docker registry
DOCKER_REGISTRY_AUTH ?= 

# Computed variables
RELEASE_CONTEXT := $(PROJECT_NAME)$(BUILD_ID)
DEV_CONTEXT := $(RELEASE_CONTEXT)dev
DEV_COMPOSE_FILE := docker/dev/docker-compose-v2.yml
REL_COMPOSE_FILE := docker/release/docker-compose.yml

# The name of the service in the Docker Compose release environment
# that represents the release image to be tagged and published 
# This must be set accurately for tagging and publshing functionality
APP_NAME ?= app

# Build tag expression - can be used to evaulate a shell expression at runtime
BUILD_TAG_EXPRESSION ?= date -u +%Y%m%d%H%M%S

# Execute shell expression
BUILD_EXPRESSION := $(shell $(BUILD_TAG_EXPRESSION))

# Build tag - defaults to BUILD_EXPRESSION if not defined
BUILD_TAG ?= $(BUILD_EXPRESSION)

.PHONY: test build release clean compose dcompose tag buildtag login logout publish

test:
	${INFO} "Creating cache volume..."
	@ docker volume create --name cache
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) pull
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) build --pull test
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) build --pull agent
#	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) build cache
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. reports;
	${CHECK} $(DEV_CONTEXT) $(DEV_COMPOSE_FILE) test
	${INFO} "Testing complete"

build:
	${INFO} "Creating builder image..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) build builder
	${INFO} "Building application artifacts..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) up builder
	${CHECK} $(DEV_CONTEXT) $(DEV_COMPOSE_FILE) builder
	${INFO} "Copying artifacts to target folder..."
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/. target
	${INFO} "Build complete"

release: 
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) pull test
	${INFO} "Building images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) build --pull nginx
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) build app
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) build webroot
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) build agent
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) run --rm agent
	${INFO} "Running database migrations..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) run --rm app manage.py migrate
	${INFO} "Collecting static files..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Running acceptance tests..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) ps -q test):/reports/. reports
	${CHECK} $(RELEASE_CONTEXT) $(REL_COMPOSE_FILE) test
	${INFO} "Acceptance testing complete"

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) down -v
#	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) kill
#	@ docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) rm -f -v
	${INFO} "Destroying release environment..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) down -v
#	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) kill
# @ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) rm -f -v
	 
	@ docker images -q --filter "label=application=$(PROJECT_NAME)" --filter "dangling=true" | xargs -I ARGS docker rmi -f ARGS
	${INFO} "Clean complete"

compose:
	${INFO} "Running docker-compose command..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) $(COMPOSE_ARGS)

dcompose:
	${INFO} "Running docker-compose command..."
	docker-compose -p $(DEV_CONTEXT) -f $(DEV_COMPOSE_FILE) $(DCOMPOSE_ARGS)

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

buildtag:
	${INFO} "Tagging release image with suffix $(BUILD_TAG) and build tags $(BUILDTAG_ARGS)..."
	@ $(foreach tag,$(BUILDTAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag).$(BUILD_TAG);)
	${INFO} "Tagging complete"

login:
	${INFO} "Logging in to Docker registry $(DOCKER_REGISTRY_AUTH)..."
	docker login -u $$DOCKER_USER -p $$DOCKER_PASSWORD -e $$DOCKER_EMAIL $(DOCKER_REGISTRY_AUTH)
	${INFO} "Logged in to Docker registry $(DOCKER_REGISTRY_AUTH)"

logout:
	${INFO} "Logging out of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"	

publish:
	${INFO} "Publishing release image $(IMAGE_ID) to $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)..."; 
	@ $(foreach tag,$(shell echo $(REPOEXPR)), docker push $(tag);)
	${INFO} "Publish complete"

# Cosmetics
YELLOW := "\e[1;33m"
RED := "\e[1;31m"
NC := "\e[0m"

# Shell Functions
MSG := @bash -c '\
  printf $$1; \
  echo "=> $$2"; \
  printf $(NC)' VALUE

INFO := ${MSG} $(YELLOW)

ERROR := ${MSG} $(RED)
 
INSPECT := $$(docker-compose -p $$1 -f $$2 ps -q $$3 | xargs -I ARGS docker inspect -f "{{ .State.ExitCode }}" ARGS)

IMAGE_ID := $$(docker inspect -f '{{ .Image }}' $$(docker-compose -p $(RELEASE_CONTEXT) -f $(REL_COMPOSE_FILE) ps -q $(APP_NAME)))

# Repository Filter
ifeq ($(DOCKER_REGISTRY), docker.io)
	REPO_FILTER := $(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
else
	REPO_FILTER := $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
endif

REPOEXPR := $$(docker inspect -f '{{range .RepoTags}}{{.}} {{end}}' $(IMAGE_ID) | grep -oh "$(REPO_FILTER)" | xargs)

CHECK := @bash -c '\
	if [[ $(INSPECT) -ne 0 ]]; \
	then exit $(INSPECT); fi' VALUE

# Extract run arguments
ifeq (compose,$(firstword $(MAKECMDGOALS)))
  COMPOSE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMPOSE_ARGS):;@:)
endif

ifeq (dcompose,$(firstword $(MAKECMDGOALS)))
  DCOMPOSE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(DCOMPOSE_ARGS):;@:)
endif

# Extract tag arguments
ifeq (tag,$(firstword $(MAKECMDGOALS)))
	TAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(TAG_ARGS),)
  	$(error You must specify a tag)
  endif
  $(eval $(TAG_ARGS):;@:)
endif

# Extract build tag arguments
ifeq (buildtag,$(firstword $(MAKECMDGOALS)))
	BUILDTAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(BUILDTAG_ARGS),)
  	$(error You must specify a tag)
  endif
  $(eval $(BUILDTAG_ARGS):;@:)
endif