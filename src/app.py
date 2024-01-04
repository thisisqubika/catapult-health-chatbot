import json
from src.saving_logic import load_context,save_context,save_context_to_parquet
from datetime import datetime
from src.app_logic import AppLogic
import logging
import boto3


def query_endpoint(payload, endpoint_name):
    client = boto3.client("sagemaker-runtime")
    response = client.invoke_endpoint(
        EndpointName=endpoint_name,
        ContentType="application/json",
        Body=json.dumps(payload),
        CustomAttributes="accept_eula=true",
    )
    response = response["Body"].read().decode("utf8")
    response = json.loads(response)
    return response



def main(event, context):
    logging.info(event)
    user_input = event.get('prompt')
    max_new_tokens = event.get('max_new_tokens')
    temperature = event.get('temperature')
    top_p = event.get('top_p')
    endpoint_name = event.get('endpoint_name')
    conversation_id = event.get('conversation_id')

    
    start_time = datetime.now()
    print(f"Function start: {start_time}")

    _ = context
    
    if not conversation_id:
        print("not getting conversation id", conversation_id)

    # Load up existing context
    memory = load_context(conversation_id)

    if endpoint_name == "GPT":
         app=AppLogic()
         response = app.handle_input(user_input)

        #  if memory and memory != []:
        #     gpt_model._update_memory(memory)
    
        #  else:
        #      pass

        #  response_generation_start = datetime.now()
        #  response = gpt_model._generate_response(user_input, HISTORY_KEY)
        #  response_generation_end = datetime.now() 
        #  print(f"Response generation duration: {response_generation_end - response_generation_start}")

        #  # save pkl
        #  save_context(conversation_id, gpt_model.memory)
        #  # save parquet files:
        #  save_context_to_parquet(conversation_id, gpt_model.memory)
    


    else:
        # Invoke the SageMaker endpoint
        payload = {
        "inputs": user_input,
        "parameters": {
            "max_new_tokens": max_new_tokens,
            "top_p": top_p,
            "temperature": temperature,
            "return_full_text": False,
        },
        }
    
        # Invoke the SageMaker endpoint
        response = query_endpoint(payload, endpoint_name)
        # Parse the response from SageMaker
        output_data = response[0]["generation"]
        text_answer = str(output_data)
        response = response

    
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    print(f"Function end: {end_time}, Total duration: {duration}")

    body = {
        "answer": response ,
        "conversation_id": conversation_id
    }

    return  {
    "statusCode": 200,
    "body": json.dumps(body),
    "headers": {
        "Content-Type": "application/json"
    }
    }
