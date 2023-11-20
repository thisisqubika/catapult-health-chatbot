# Use an official miniconda image as a parent image
FROM continuumio/miniconda3

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . /usr/src/app

# Create the environment using a single RUN command to minimize layers
RUN conda create --name snowpark-llm-chatbot --override-channels -c conda-forge python=3.10 numpy pandas python-dotenv snowflake-sqlalchemy && \
    conda clean --all --yes

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "snowpark-llm-chatbot", "/bin/bash", "-c"]

# Install the required packages and clear Conda tarballs to reduce image size
RUN conda install -c conda-forge plotly \
    && conda clean --all --yes && \
    pip install streamlit openai==0.28.0 boto3 snowflake-snowpark-python && \
    conda clean --all --yes \
    && pip install --upgrade langchain \
    && pip install --upgrade langchain-experimental

# Make src/app.py executable
RUN chmod +x ./src/refactor/app.py

# Expose the port the app runs on
EXPOSE 8501

# Set the command to run the Streamlit app
CMD ["conda", "run", "--no-capture-output", "-n", "snowpark-llm-chatbot", "streamlit", "run", "./src/refactor/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
