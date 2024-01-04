import json

from index import handler

# event = {
#     "prompt": "Hola! necesito codigo de python para crear un dataframe con la poblacion de uruguay en montevideo",
#     "max_new_tokens": 350,
#     "top_p": 0.9,
#     "temperature": 0.6,
#     "endpoint_name": "GPT",
#     "conversation_id": 'asfg123456'
# }


event = {"prompt": 'How many participants have registered for each Company?',
  "max_new_tokens": 350,
  "temperature": 0.3,
  "top_p": 0.9,
  "endpoint_name": 'GPT',
  "conversation_id": '657c4b19ad3327bf09f7e33516'}

# "Hola! necesito codigo de python para crear un dataframe con la poblacion de uruguay en montevideo
# Ahora necesito agregar el departamento de maldonado
context = {}

response = handler(event, context)

print(json.dumps(response, indent=4))