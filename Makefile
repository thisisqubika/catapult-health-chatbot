SHELL=/bin/bash
PATH := .venv/bin:$(PATH)
export TEST?=./tests
export LAMBDA?=catapult-health-api
export IMG_NAME=img-catapult-health-api
export IMAGE_TAG=latest
export REPO=lambda-${LAMBDA}
export ENV?=dev
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=789524919849
export ECR_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
export TAG_NAME=${LAMBDA}-${ENV}
export VERSION=latest

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

build-package:
	@echo "Building package";
	@if [ ! -d terraform/global/build ]; then mkdir ./terraform/global/build; fi;
	@pip install -r requirements.txt -t ./requirements;
	@cp -r ./requirements ./temporary_directory/;
	@cp -r  ./src ./temporary_directory/;
	@cp ./requirements.txt ./index.py ./temporary_directory/;
	@(cd ./temporary_directory && zip -r llm-llama-to-endpoint.zip ./*);
	@if [ -d ./terraform/global/build/requirements ]; then rm -r ./terraform/global/build/requirements; fi;
	@mv ./requirements ./temporary_directory/llm-llama-to-endpoint.zip ./terraform/global/build/;
	@rm -r ./temporary_directory;

validate-tf-workspaces:
	@( \
		cd terraform/workspaces;  \
		terraform init; \
		printf "\033[0;34mValidating workspaces...\034\n"; \
		terraform validate; \
	)

validate-tf:
	@( \
		cd terraform/global;  \
		terraform init; \
		printf "\033[0;34mValidating terraform...\034\n"; \
		terraform validate; \
	)

validate-plan: 
	@( \
		cd terraform;  \
		terraform init; \
		printf "\033[0;34mValidating terraform...\034\n"; \
		terraform validate; \
		printf "\033[0;34mPlanning terraform...\034\n"; \
		terraform plan; \
	)

validate-apply:
	@( \
		cd terraform;  \
		terraform init; \
		printf "\033[0;34mValidating terraform...\034\n"; \
		terraform validate; \
		printf "\033[0;34mPlanning terraform...\034\n"; \
		terraform plan; \
		printf "\033[0;34mApplying terraform...\034\n"; \
		terraform apply -auto-approve; \
	)

invoke-local:
	@cat event.local.json | base64 > event.local.base64
	@aws lambda invoke --function-name $${LAMBDA} --payload file://event.local.base64 response.json
	@if [ -f response.json ]; then python -B -m json.tool response.json; fi
	@rm -f event.local.base64

build:
	@docker build --platform=linux/amd64 -t ${IMG_NAME} .

local-build:
	@docker build -t ${IMG_NAME} .

to-ecr:
	@$(shell ./push_ecr.sh ${AWS_ACCOUNT_ID} ${AWS_REGION})

create-ecr:
	@$(shell   aws ecr create-repository \
    --repository-name  ${IMG_NAME} \
    --image-scanning-configuration scanOnPush=true \
    --region ${AWS_REGION})

image-tag:
	@docker tag ${IMG_NAME} ${ECR_URL}/${IMG_NAME}:${IMAGE_TAG}

#do aws login and push to ecr
push-ecr:
	@aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}
	@docker push ${ECR_URL}/${IMG_NAME}:${IMAGE_TAG}
	

#create lambda function with the latest image
create-lambda:
	@aws lambda create-function \
		--function-name ${LAMBDA} \
		--package-type Image \
		--timeout 300 \
		--memory-size 128 \
		--code ImageUri=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMG_NAME}:${VERSION} \
		--role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-llm-llama-to-endpoint-demo

update-lambda:
	@aws lambda update-function-code \
		--function-name ${LAMBDA} \
		--image-uri ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMG_NAME}:${VERSION}

run-dev:
	@( \
		if [ ! -d .venv ];then python3 -m venv .venv;fi; \
		source .venv/bin/activate; \
		python3 index.py; \
	)

run:
	@docker run -d -p 8000:5000 ${IMG_NAME}

.PHONY: tests docs