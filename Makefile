PROJECT_NAME ?= todobackend
ORG_NAME ?= cloudhotspot
REPO_NAME ?= todobackend

# Computed variables
RELEASE_CONTEXT = $(PROJECT_NAME)$(BUILD_ID)
DEV_CONTEXT = $(RELEASE_CONTEXT)dev

# Tagging: this must match the release environment application service in docker/release/docker-compose.yml
APP_NAME ?= app

.PHONY: test build release clean compose tag publish

test:
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml pull
	${INFO} "Building images..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml build --pull
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml run --rm agent
	${INFO} "Running tests..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml up test
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml ps -q test):/reports/. reports
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml rm -f -v test
	${INFO} "Testing complete"

build:
	${INFO} "Building application artefacts..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml up builder
	${INFO} "Copying artefacts to target folder..."
	@ docker cp $$(docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml ps -q builder):/wheelhouse/. target
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml rm -f -v builder
	${INFO} "Build complete"

release: 
	${INFO} "Pulling latest images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml pull
	${INFO} "Building images..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml build --pull
	${INFO} "Ensuring database is ready..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm agent
	${INFO} "Running database migrations..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm app manage.py migrate
	${INFO} "Collecting static files..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml run --rm app manage.py collectstatic --noinput
	${INFO} "Running acceptance tests..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml up test
	@ docker cp $$(docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml ps -q test):/reports/. reports
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml rm -f -v test
	${INFO} "Acceptance testing complete"

clean:
	${INFO} "Destroying development environment..."
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml kill
	@ docker-compose -p $(DEV_CONTEXT) -f docker/dev/docker-compose.yml rm -f -v
	${INFO} "Destroying release environment..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml kill
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml rm -f -v
	${INFO} "Removing dangling images..."
	@ docker images -q --filter "label=application=$(PROJECT_NAME)" --filter "dangling=true" | xargs -I ARGS docker rmi ARGS
	${INFO} "Remove build folder..."
	@ rm -rf target
	${INFO} "Clean complete"

compose:
	${INFO} "Running docker-compose command..."
	@ docker-compose -p $(RELEASE_CONTEXT) -f docker/release/docker-compose.yml $(COMPOSE_ARGS)

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag -f $(RELEASE_CONTEXT)_$(APP_NAME) $(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

publish:
	${INFO} "Publishing release image $(ORG_NAME)/$(REPO_NAME)..."
	$(foreach tag,$(PUBLISH_ARGS), docker push $(ORG_NAME)/$(REPO_NAME):$(tag);)
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
  $(eval $(TAG_ARGS):;@:)
endif

# Extract push arguments
ifeq (publish, $(firstword $(MAKECMDGOALS)))
  PUBLISH_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(PUBLISH_ARGS),)
  	$(error You must specify a tag to publish)
  endif
  $(eval $(PUBLISH_ARGS):;@:)
endif