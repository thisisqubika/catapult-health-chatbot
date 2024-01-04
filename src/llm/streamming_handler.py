from langchain.callbacks.base import BaseCallbackHandler
from langchain.schema.messages import AIMessageChunk

class StreamHandler(BaseCallbackHandler):
    def __init__(self, container, initial_text=""):
        self.container = container
        self.text = initial_text

    def on_llm_new_token(self, token: AIMessageChunk, **kwargs) -> None:
        # Ensure that the token.content is a string and not a Streamlit object
        if isinstance(token.content, str):
            # Append the content to self.text
            self.text += token.content
            # Update the container with the current text
            self.container.markdown(self.text)



