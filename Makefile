PROJECT_NAME ?= todobackend
ORG_NAME ?= cloudhotspot
REPO_NAME ?= todobackend

# Use this setting to specify a custom Docker registry
DOCKER_REGISTRY ?= docker.io

# Computed variables
RELEASE_CONTEXT := $(PROJECT_NAME)$(BUILD_ID)
DEV_CONTEXT := $(RELEASE_CONTEXT)dev

# Tagging: this must match the release environment application service in docker/release/docker-compose.yml
APP_NAME ?= app

.PHONY: test build release clean compose tag login logout publish $(MAKECMDGOALS)

test:
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml pull
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml build --pull test
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml build --pull agent
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml build cache
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml up test
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml ps -q test):/reports/. reports;
	${CHECK} $(DEV_CONTEXT) docker/dev/docker-compose.yml test
	${INFO} "Testing complete"

build:
	${INFO} "Creating builder image..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml build builder
	${INFO} "Building application artifacts..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml up builder
	${CHECK} $(DEV_CONTEXT) docker/dev/docker-compose.yml builder
	${INFO} "Copying artifacts to target folder..."
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml ps -q builder):/wheelhouse/. target
	${INFO} "Build complete"

release: 
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml pull test
	${INFO} "Building images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml build --pull nginx
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml build app
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml build webroot
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml build agent
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm agent
	${INFO} "Running database migrations..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm app manage.py migrate
	${INFO} "Collecting static files..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm app manage.py collectstatic --noinput
	${INFO} "Running acceptance tests..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml up test
	@ docker cp $$(docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml ps -q test):/reports/. reports
	${CHECK} $(RELEASE_CONTEXT) docker/release/docker-compose.yml test
	${INFO} "Acceptance testing complete"

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml kill
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml rm -f -v
	${INFO} "Destroying release environment..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml kill
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml rm -f -v
	${INFO} "Removing dangling images..."
	@ docker images -q --filter "label=application=$(PROJECT_NAME)" --filter "dangling=true" | xargs -I ARGS docker rmi -f ARGS
	${INFO} "Clean complete"

compose:
	${INFO} "Running docker-compose command..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml $(COMPOSE_ARGS)

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(shell echo $(TAG_ARGS)), docker tag -f $(RELEASE_CONTEXT)_$(APP_NAME) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

login:
	${INFO} "Logging in to Docker registry $(DOCKER_REGISTRY)..."
	@ docker login -u $$DOCKER_USER -p $$DOCKER_PASSWORD -e $$DOCKER_EMAIL $(DOCKER_REGISTRY)
	${INFO} "Logged in to Docker registry $(DOCKER_REGISTRY)"

logout:
	${INFO} "Logging out of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"	

publish:
	${INFO} "Publishing tags $(PUBLISH_ARGS) for release image $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)..."; 
	@ $(foreach tag,$(PUBLISH_ARGS), docker push $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	@ $(if $(PUBLISH_ARGS),, docker push $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME))
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

CHECK := @bash -c '\
	if [[ $(INSPECT) -ne 0 ]]; \
	then exit $(INSPECT); fi' VALUE

# Extract run arguments
ifeq (compose,$(firstword $(MAKECMDGOALS)))
  COMPOSE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMPOSE_ARGS):;@:)
endif

# Extract tag arguments
ifeq (tag,$(firstword $(MAKECMDGOALS)))
	TAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(TAG_ARGS),)
  	$(error You must specify a tag)
  endif

endif

# Extract push arguments
ifeq (publish, $(firstword $(MAKECMDGOALS)))
  PUBLISH_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(PUBLISH_ARGS):;@:)
endif