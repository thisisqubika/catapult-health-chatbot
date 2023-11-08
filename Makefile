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
		if [ ! -d .venv ]; then make install; fi; \
		source .venv/bin/activate; \
		streamlit run src/app.py; \
	)

.PHONY: tests docs

create-ecr:
	@aws lightsail create-container-service --service-name ${LAMBDA} --power nano --scale 1

push-app:
	@aws lightsail push-container-image --region ${AWS_REGION} --service-name ${LAMBDA} --label ${LAMBDA} --image "${LAMBDA}:${VERSION}"

# --profile moove-it 
	
# deploy:
# 	@$(eval IMAGE_TAG := $(shell git rev-parse --short HEAD))
# 	@$(eval FULL_IMAGE_NAME := "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${LAMBDA}:${IMAGE_TAG}")

# 	@sed -i "s|:catapult-health-chatbot.catapult-health-chatbot:TAG_PLACEHOLDER|${FULL_IMAGE_NAME}|g" containers.json
# 	@aws lightsail create-container-service-deployment --service-name ${LAMBDA} --containers file://containers.json --public-endpoint file://public-endpoint.json

deploy:
	@$(eval IMAGE_TAG := $(shell git rev-parse --short HEAD))
	@$(eval FULL_IMAGE_NAME := "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${LAMBDA}:${IMAGE_TAG}")

deploy:
	@$(eval IMAGE_TAG := $(shell git rev-parse --short HEAD))
	@$(eval FULL_IMAGE_NAME := "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${LAMBDA}:${IMAGE_TAG}")

	@echo "{" > containers.json
	@echo "  \"containers\": {" >> containers.json
	@echo "    \"${LAMBDA}\": {" >> containers.json
	@echo "      \"image\": \"${FULL_IMAGE_NAME}\"," >> containers.json
	@echo "      \"ports\": {" >> containers.json
	@echo "        \"8501\": \"HTTP\"" >> containers.json
	@echo "      }," >> containers.json
	@echo "      \"environment\": {}," >> containers.json
	@echo "      \"healthCheck\": {" >> containers.json
	@echo "        \"healthyThreshold\": 2," >> containers.json
	@echo "        \"unhealthyThreshold\": 5," >> containers.json
	@echo "        \"timeoutSeconds\": 4," >> containers.json
	@echo "        \"intervalSeconds\": 30," >> containers.json
	@echo "        \"path\": \"/healthcheck\"" >> containers.json
	@echo "      }" >> containers.json
	@echo "    }" >> containers.json
	@echo "  }" >> containers.json
	@echo "}" >> containers.json
	
	@aws lightsail create-container-service-deployment --service-name ${LAMBDA} --containers file://containers.json --public-endpoint file://public-endpoint.json

check-state:
	@aws lightsail get-container-services --service-name ${LAMBDA}

cleanup:
	@aws lightsail delete-container-service --service-name ${LAMBDA}

get-version:
	@echo $(VERSION)