# Use an official miniconda image as a parent image
FROM continuumio/miniconda3

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . /usr/src/app

# Create the Conda environment
RUN conda create --name snowpark-llm-chatbot --override-channels -c conda-forge python=3.10 numpy pandas

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "snowpark-llm-chatbot", "/bin/bash", "-c"]

# Attempt to install the required packages in the created Conda environment with retries
RUN for i in {1..5}; do conda install -c conda-forge snowflake-snowpark-python openai && break || sleep 15; done

# Install Streamlit
RUN pip install streamlit
RUN pip install openai==0.28.0

# Make src/app.py executable
RUN chmod +x ./src/app.py

# Expose the port the app runs on
EXPOSE 8501

# Set the command to run the Streamlit app
CMD ["conda", "run", "--no-capture-output", "-n", "snowpark-llm-chatbot", "streamlit", "run", "./src/app.py", "--server.port=8501", "--server.address=0.0.0.0"]


