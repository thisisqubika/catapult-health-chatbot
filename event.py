import json

from index import handler

event = {}

context = {}

response = handler(event, context)

print(json.dumps(response, indent=4))
