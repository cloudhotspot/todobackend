PROJECT_NAME ?= todobackend
ORG_NAME ?= cloudhotspot
REPO_NAME ?= todobackend

# This must match the release environment application service in docker/release/docker-compose.yml
APP_NAME ?= app

.PHONY: test build release clean compose tag publish

test:
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml pull
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml build --pull
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml run --rm test
	${INFO} "Testing complete"

build:
	${INFO} "Building application artefacts..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml run --rm builder
	${INFO} "Build complete"

release: 
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml pull
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml build --pull
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml run --rm agent
	${INFO} "Running database migrations..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml run --rm app manage.py migrate
	${INFO} "Collecting static files..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml run --rm app manage.py collectstatic --noinput
	${INFO} "Running acceptance tests..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml run --rm test
	${INFO} "Acceptance testing complete"

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml kill
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml rm -f -v
	${INFO} "Destroying release environment..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml kill
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml rm -f -v
	${INFO} "Removing dangling images..."
	@ docker images -q --filter "label=application=$(PROJECT_NAME)" --filter "dangling=true" | xargs -I ARGS docker rmi ARGS
	${INFO} "Clean complete"

compose:
	${INFO} "Running docker-compose command..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml $(COMPOSE_ARGS)

tag:
	${INFO} "Tagging release image as $(GIT_BRANCH).$(GIT_SHA)..."
	docker tag -f $(PROJECT_NAME)_$(APP_NAME) $(ORG_NAME)/$(REPO_NAME):$(GIT_BRANCH).$(GIT_SHA)
	if [[ -n "$$BUILD_ID" ]]; then docker tag -f $(PROJECT_NAME)_$(APP_NAME) $(ORG_NAME)/$(REPO_NAME):$(GIT_BRANCH).$$BUILD_ID; fi
	if [[ "$(GIT_BRANCH)" -eq "master" ]]; then docker tag -f $(PROJECT_NAME)_$(APP_NAME) $(ORG_NAME)/$(REPO_NAME):latest; fi
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag -f $(PROJECT_NAME)_$(APP_NAME) $(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

publish:
	${INFO} "Publishing release image $(ORG_NAME)/$(REPO_NAME)..."
	@ docker push $(ORG_NAME)/$(REPO_NAME)
	${INFO} "Publish complete"

# Cosmetics
YELLOW = "\033[1;33m"
NC = "\033[0m"

# Shell Functions
INFO=@sh -c '\
  printf $(YELLOW); \
  echo "=> $$1"; \
  printf $(NC)' INFO

# Git metadata
GIT_BRANCH = $$(git rev-parse --abbrev-ref HEAD)
GIT_SHA = $$(git rev-parse --short HEAD)

# Extract run arguments
ifeq (compose,$(firstword $(MAKECMDGOALS)))
  COMPOSE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMPOSE_ARGS):;@:)
endif

# Extract tag arguments
ifeq (tag,$(firstword $(MAKECMDGOALS)))
  TAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(TAG_ARGS):;@:)
endif