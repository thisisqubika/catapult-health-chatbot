from pathlib import Path
from typing import Sequence, Tuple, Any, Mapping, Type, Optional
import yaml
from pydantic import Field, BaseModel
from pydantic.fields import FieldInfo

class ModelEndpoint(BaseModel):
    llm_name: str
    endpoint_name: str


class ModelParameters(BaseModel):
    """Configuration class for the LLM generation parameters."""
    
    # SAGEMAKER LLAMA2 PARAMS:
    max_tokens: int = Field(default_factory=int, description="The maximum number of tokens to generate.")
    top_p: Optional[float] = Field(default_factory=float, description="The top-p value for the generation.")
    temperature: float = Field(default_factory=float, description="The temperature value for the generation.")
    stream_response: Optional[bool] = Field(default_factory=bool, description="Whether to return the whole text or stream it.")


    # OPENAI PARAMS:
    streaming: Optional[bool] = Field(default=True, description="Whether to return the whole text or stream it.")
    verbose: Optional[bool] = Field(default=True, description="Verbosity of the response")
    openai_api_key: Optional[str] = Field(default_factory=str, description="OPENAI API KEY retrieved from SSM AWS")
    # model: Optional[str] = Field(default_factory=str, description="model_endpoint_name")


class MemoryParameters(BaseModel):
    """LLM memory parameters configuration class."""
    table: str = Field(default_factory=str, description="The name of the DynamoDB table to use.")


class LlmConfig(BaseModel):
    """The configuration parameters related to LLMs."""
    endpoints: Sequence[ModelEndpoint] = Field(default_factory=list, description="The name of the LLM model to use.")
    parameters: ModelParameters = Field(default_factory=ModelParameters, description="Parameters for LLM generation")
    memory: MemoryParameters = Field(default_factory=MemoryParameters, description="Parameters for memory")


class AwsConfig(BaseModel):
    """Configuration class for AWS parameters."""
    region: str = Field(default_factory=str, description="The AWS region to use.")


class Config(BaseSettings):
    llm: LlmConfig = LlmConfig()
    aws: AwsConfig = AwsConfig()

    # Load YAML configuration
    @classmethod
    def load_yaml_config(cls):
        with open("./default.config.yaml", "r", encoding="utf-8") as file:
            yaml_config = yaml.safe_load(file)
        return yaml_config

    # Override the constructor to merge YAML config
    def __init__(self, **values):
        yaml_config = self.load_yaml_config()
        super().__init__(**yaml_config, **values)



config = Config()