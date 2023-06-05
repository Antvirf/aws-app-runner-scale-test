SHELL := /bin/bash

.PHONY: buildc runc infra test

buildc:
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build . -t aws-app-runner-scale-test:test --platform linux/amd64

runc:
	docker rm awsarscale || echo ""
	DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run --platform linux/amd64 -p 8080:8080 --name awsarscale aws-app-runner-scale-test:test

infra:
	cd infra && \
	terraform init && \
	terraform apply

loadtest:
	cd loadtests && \
	k6 run --out json=result.json main.js