import os
import uuid
import pickle
import boto3
from src.utils.constants import HISTORY_KEY
import traceback
from langchain.schema.messages import AIMessage,HumanMessage
from langchain.memory import ConversationBufferMemory
import pandas as pd
from datetime import datetime
import io

S3_ASSETS_BUCKET_NAME = "catapult-health-bot"
parquet_file_key = "data/conversations.parquet"
s3 = boto3.resource('s3')

bucket = s3.Bucket(S3_ASSETS_BUCKET_NAME)


def save_context_to_parquet(connection_id, chain_memory: ConversationBufferMemory):
    try:
        history_to_save = chain_memory.load_memory_variables({})[HISTORY_KEY]
        current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        last_aimessage = next((m.content for m in reversed(history_to_save) if isinstance(m, AIMessage)), None)
        last_humanmessage = next((m.content for m in reversed(history_to_save) if isinstance(m, HumanMessage)), None)

        interaction_id = uuid.uuid4().hex
        parquet_upload_key = f"data/{interaction_id}.parquet"

        df = pd.DataFrame({
            'connection_id': [connection_id],
            'human_message': [last_humanmessage],
            'ai_message': [last_aimessage],
            'created_at': [current_time]
        })

        parquet_buffer = io.BytesIO()
        df.to_parquet(parquet_buffer)

        s3.Object(S3_ASSETS_BUCKET_NAME, parquet_upload_key).put(Body=parquet_buffer.getvalue())

    except Exception as e:
        print(f"Error in save_context: {e}")
        traceback.print_exc()

    

def save_context(connection_id, chain_memory: ConversationBufferMemory):

    history_to_save = chain_memory.load_memory_variables({})
    if 'chat_history' in history_to_save:
        history_to_save = history_to_save[HISTORY_KEY]
    else:
        raise KeyError('chat_history not found in chain_memory')

    # history_to_save = chain_memory.load_memory_variables({})[HISTORY_KEY]

    upload_key = f"context/{connection_id}/chat_history.pkl"

    # Serialize and upload directly to S3
    with open("/tmp/chat_history.pkl", "wb") as f:
        pickle.dump(history_to_save, f)
    bucket.upload_file("/tmp/chat_history.pkl", upload_key)



def load_context(connection_id):
    try:
        upload_key = f"context/{connection_id}/chat_history.pkl"  # Same key as in saving logic
        file_path = f"/tmp/chat_history.pkl"
        bucket.download_file(upload_key, file_path)

        with open(file_path, "rb") as f:
            loaded_memory = pickle.load(f)

        return loaded_memory if isinstance(loaded_memory, list) else None
    except Exception as e:
        print(f"Failed to load context: {e}")
        return None
