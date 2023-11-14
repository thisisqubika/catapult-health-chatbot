import logging
import os
import re
import sys
import requests
import openai
import streamlit as st
from dotenv import load_dotenv
from prompts import get_system_prompt
from snowflake.connector.errors import ProgrammingError 

load_dotenv()

# Set up root logger to output to stdout
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

# Example of logging in your application code
logger = logging.getLogger(__name__)
logger.info("This is an informational message.")

st.title("🏥 Catapult-Healthcare Bot")

openai.api_key = os.environ.get("OPENAI_API_KEY")

# Initialize st.session_state if it's not already initialized
if not hasattr(st, "session_state"):
    st.session_state = {}

if "messages" not in st.session_state:
    st.session_state.messages = [{"role": "system", "content": get_system_prompt()}]

# Prompt for user input and save
if prompt := st.chat_input():
    st.session_state.messages.append({"role": "user", "content": prompt})

# Display the existing chat messages
for message in st.session_state.messages:
    if message["role"] == "system":
        continue
    with st.chat_message(message["role"]):
        st.write(message["content"])
        if "results" in message:
            st.dataframe(message["results"])

# If last message is not from assistant, we need to generate a new response

if st.session_state.messages[-1]["role"] != "assistant":
    with st.chat_message("assistant"):
        response = ""
        resp_container = st.empty()  # Define resp_container here
        retry_count = 0
        max_retries = 3

        while retry_count < max_retries:
            try:
                for delta in openai.ChatCompletion.create(
                    model="gpt-4-1106-preview",
                    messages=[
                        {"role": m["role"], "content": m["content"]}
                        for m in st.session_state.messages
                    ],
                    stream=True,
                ):
                    response += delta.choices[0].delta.get("content", "")
                    resp_container.markdown(response)
                
                message = {"role": "assistant", "content": response}

                # Parse the response for a SQL query
                sql_match = re.search(r"```sql\n(.*)\n```", response, re.DOTALL)
                if sql_match:
                    sql = sql_match.group(1)
                    conn = st.connection("snowflake")
                    message["results"] = conn.query(sql)
                    st.dataframe(message["results"])
                
                st.session_state.messages.append(message)
                # If successful, exit the loop
                break

            except (requests.exceptions.ChunkedEncodingError, ProgrammingError) as e:
                retry_count += 1
                logger.error(f"Error occurred: {e}. Retrying...")

        if retry_count == max_retries:
            logger.error("Max retries reached. Unable to get a response.")
            # Handle the case where max retries have been reached


# #############################
################################