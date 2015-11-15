.PHONY: test build release clean 

test:
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml build
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml run --rm agent
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml run --rm test

build:
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml run --rm builder

release: 
	docker-compose -p todobackend -f docker/release/docker-compose.yml build
	docker-compose -p todobackend -f docker/release/docker-compose.yml run --rm agent
	docker-compose -p todobackend -f docker/release/docker-compose.yml run --rm app manage.py migrate
	docker-compose -p todobackend -f docker/release/docker-compose.yml run --rm app manage.py collectstatic --noinput
	docker-compose -p todobackend -f docker/release/docker-compose.yml run --rm test

clean:
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml kill
	docker-compose -p todobackend-dev -f docker/dev/docker-compose.yml rm -f -v
	docker-compose -p todobackend -f docker/release/docker-compose.yml kill
	docker-compose -p todobackend -f docker/release/docker-compose.yml rm -f -v
	docker images -q --filter "dangling=true" | xargs -I ARGS docker rmi ARGS
