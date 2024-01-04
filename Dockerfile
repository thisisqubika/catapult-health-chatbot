FROM public.ecr.aws/lambda/python:3.10

ADD . ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

# Add the Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.7.0 /lambda-adapter /opt/extensions/lambda-adapter

# Set the AWS_LWA_INVOKE_MODE environment variable
ENV AWS_LWA_INVOKE_MODE=response_stream

CMD ["index.handler"]