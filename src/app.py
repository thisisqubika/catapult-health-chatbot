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

                # Find all SQL queries in the response and take the last one
                sql_queries = re.findall(r"```sql\n(.*?)\n```", response, re.DOTALL)
                if sql_queries:
                    sql = sql_queries[-1]  # Execute only the last SQL query
                    conn = st.connection("snowflake")
                    try:
                        message["results"] = conn.query(sql)
                        st.dataframe(message["results"])
                        break
                    except ProgrammingError as e:
                        logger.error(f"SQL Execution Error: {e}")
                        # Do not increase retry_count here as we want to retry with the same response
                else:
                    logger.error("No SQL query found in response.")
                    break  # Exit the loop if no SQL found

                retry_count += 1

            except requests.exceptions.ChunkedEncodingError as e:
                retry_count += 1
                logger.error(f"Error occurred: {e}. Retrying...")

        if retry_count == max_retries:
            logger.error("Max retries reached. Unable to get a response.")
            # Handle the case where max retries have been reached
        
        message = {"role": "assistant", "content": response}
        st.session_state.messages.append(message)
