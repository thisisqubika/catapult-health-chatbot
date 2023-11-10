import boto3


def get_ssm_parameter(parameter_name, ENV):
    """Get parameter from SSM."""
    ssm = boto3.client("ssm")
    parameter = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    return parameter["Parameter"]["Value"]
