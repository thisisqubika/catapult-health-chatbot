import streamlit as st
new_loader = st.empty()
new_loader.text("Loading... please wait. ")

from app_logic import AppLogic


# Title
st.title("🏥 Catapult-Health Chatbot")
new_loader.empty()
# Instantiate the app logic
app_logic = AppLogic()
new_loader.text("Setting database connections... ")

# Initialize st.session_state if it's not already initialized
if not hasattr(st, "session_state"):
    st.session_state = {}

new_loader.empty()

if "messages" not in st.session_state:
    st.session_state.messages = [{"role": "system", "content": app_logic.system_generator.generate_response()}]

# user_input for user input and save
if prompt := st.chat_input():
    st.session_state.messages.append({"role": "user", "content": prompt}) 


if st.session_state.messages[-1]["role"] != "system":
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            # Directly output the content if it's a string
            if isinstance(message["content"], str):  # Check if content is a string
                st.markdown(message["content"])  # Use markdown to preserve any formatting
            if "results" in message:
                st.dataframe(message["results"])




# If last message is not from assistant, we need to generate a new response:
if st.session_state.messages[-1]["role"] != "assistant":
    with st.chat_message("assistant"):
        session = app_logic.handle_input(prompt, st.session_state)
