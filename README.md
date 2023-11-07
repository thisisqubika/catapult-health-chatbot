# Streamlit Example with AWS Lightsail

This repository is a proof-of-concept project that demonstrates the usage of Streamlit within an application running on AWS Lightsail. It showcases how to integrate the Streamlit and provides examples of commands for building the container and pushing it to your AWS account.

## Overview

The project consists of a sample web application that allows users to interact with Streamlit through a user interface.

## Prerequisites

Before running the application, make sure you have the following:

- AWS Lightsail account.
- AWS Cli installed and configured.

## Installation

To set up the project, follow these steps:

1. Clone the repository: `git clone git@github.com:moove-it/catapult-health-chatbot.git`
2. Install the required dependencies: `make install`

## Usage

1. Build the Docker container: `make local-build`
2. Run the Docker container locally: `make run`
3. Access the application in your browser: `http://localhost:8000`

## Deployment

To manually deploy the application to AWS Lightsail, follow these steps:

1. Create a Docker image to run in aws: `make build`
2. Create the Lightsail container service: `make create-ecr`
3. Push the application container to Lightsail with the `make push-app` command.
3. 1. Note: the X in ":flask-container.flask-container.X" will be a numeric value. If this is the first time you’ve pushed an image to your container service, this number will be 1. You will need this number in the next step.
3. 2. Update the containers.json file with the new image number.
4. Deploy the application to Lightsail with the `make deploy` command. (Note: before running this command, make sure you have updated the containers.json file with the new image number.)


## Troubleshooting

If you encounter any issues when running the application, try the following:

- Make sure you have the latest righ version of the "containerName": "catapult-health-chatbot", in the containers.json file.

## CI/CD Pipeline to AWS Lightsail (github actions enabled)

1. Configure the following secrets in your repository:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY

2. Push your changes to the repository and the pipeline will be triggered.

## References

For more information on the technologies and services used in this project, refer to the following resources:

- [AWS Lightsail Documentation](https://lightsail.aws.amazon.com/)
- [Streamlit Documentation](https://docs.streamlit.io/)

## License

This project is licensed under the [MIT License](LICENSE).


#### Contact

- Email: `marcos.soto@qubika.com`
- Slack: #`# MLE's development channel`
