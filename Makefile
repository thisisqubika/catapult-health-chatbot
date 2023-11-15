SHELL=/bin/bash
PATH := .venv/bin:$(PATH)
export TEST?=./tests
export LAMBDA?=catapult-health-chatbot
export IMG_NAME=img-catapult-health-chatbot
export IMAGE_TAG=latest
export REPO=lambda-${LAMBDA}
export ENV?=dev
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=789524919849
export ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
export TAG_NAME=${LAMBDA}-${ENV}
# export VERSION=latest
export VERSION=$(shell git rev-parse --short HEAD)


install:
	@( \
		if [ ! -d .venv ]; then python3 -m venv --copies .venv; fi; \
		source .venv/bin/activate; \
		pip install -qU pip; \
		pip install -r requirements-dev.txt; \
		pip install -r requirements.txt; \
	)

setup:
	@if [ ! -f .env ] ; then cp .env.mock .env ; fi;
	@make install;

autoflake:
	@autoflake . --check --recursive --remove-all-unused-imports --remove-unused-variables --exclude .venv;

black:
	@black . --check --exclude '.venv|build|target|dist|.cache|node_modules';

isort:
	@isort . --check-only;

lint: black isort autoflake

lint-fix:
	@black . --exclude '.venv|build|target|dist';
	@isort .;
	@autoflake . --in-place --recursive --exclude .venv --remove-all-unused-imports --remove-unused-variables;

docs:
	@if [ ! -f ./docs/make.bat ]; then (cd docs && sphinx-quickstart); fi;
	@(cd docs && make html);
	@if command -v open; then open ./docs/*build/html/index.html; fi;

tests:
	@python -B -m pytest -l --color=yes \
		--cov=src \
		--cov-config=./tests/.coveragerc \
		--cov-report term \
		--cov-report html:coverage \
		--junit-xml=junit.xml \
		--rootdir=. $${TEST};

build:
	@docker build --platform=linux/amd64 -t ${LAMBDA}:${VERSION} .

# --build-arg OPENAI_API_KEY=$(grep OPENAI_API_KEY .env | cut -d '=' -f2) 
build-local-to-aws:
	@docker build --platform=linux/amd64 -t ${LAMBDA} .

push:
	@aws lightsail push-container-image --service-name "${LAMBDA}" --label "${LAMBDA}" --image "${LAMBDA}:${VERSION}"

local-build:
	@docker build -t ${LAMBDA} .

run:
	@docker run -d -p 8501:8501 ${LAMBDA}
# :${VERSION}
stop:
	@docker stop $$(docker ps -a -q)

run-dev:
	@(\
		export OPENAI_API_KEY=$$(cat .env | grep OPENAI_API_KEY | cut -d '=' -f2); \
		if [ ! -d .venv ]; then make install; fi; \
		source .venv/bin/activate; \
		python src/app.py; \
	)

.PHONY: tests docs

create-ecr:
	@aws lightsail create-container-service --service-name ${LAMBDA} --power nano --scale 1

push-app:
	@aws lightsail push-container-image --region ${AWS_REGION} --service-name ${LAMBDA} --label ${LAMBDA} --image "${LAMBDA}:${VERSION}"

push-app-local:
	@aws lightsail push-container-image --region ${AWS_REGION} --service-name ${LAMBDA} --label ${LAMBDA} --image "${LAMBDA}:latest"	


# --profile moove-it 
	
# deploy:
# 	@$(eval IMAGE_TAG := $(shell git rev-parse --short HEAD))
# 	@$(eval FULL_IMAGE_NAME := "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${LAMBDA}:${IMAGE_TAG}")

# 	@sed -i "s|:catapult-health-chatbot.catapult-health-chatbot:TAG_PLACEHOLDER|${FULL_IMAGE_NAME}|g" containers.json
# 	@aws lightsail create-container-service-deployment --service-name ${LAMBDA} --containers file://containers.json --public-endpoint file://public-endpoint.json

# IMG_TAG en vez de VERSION en la segunda linea del deploy que tiene la FULL_IMAGE_NAME	
deploy:
	@$(eval IMAGE_TAG := $(shell git rev-parse --short HEAD))
	@$(eval FULL_IMAGE_NAME := "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${LAMBDA}:${VERSION}")
	@sed "s|your-image-name|${FULL_IMAGE_NAME}|g" containers-template.json > containers.json
	@sed "s|catapult-health-chatbot|${LAMBDA}|g" public-endpoint-template.json > public-endpoint.json
	@aws lightsail create-container-service-deployment --service-name ${LAMBDA} --containers file://containers.json --public-endpoint file://public-endpoint.json

check-state:
	@aws lightsail get-container-services --service-name ${LAMBDA}

cleanup:
	@aws lightsail delete-container-service --service-name ${LAMBDA}

get-version:
	@echo $(VERSION)