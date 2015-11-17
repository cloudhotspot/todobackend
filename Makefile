PROJECT_NAME ?= todobackend

.PHONY: test build release clean compose

test:
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT_NAME)-dev -f docker/dev/docker-compose.yml build
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
	${INFO} "Building images..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml build
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
	@ docker images -q --filter "dangling=true" | xargs -I ARGS docker rmi ARGS
	${INFO} "Clean complete"

compose:
	${INFO} "Running docker-compose command..."
	@ docker-compose -p $(PROJECT_NAME) -f docker/release/docker-compose.yml $(COMPOSE_ARGS)

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