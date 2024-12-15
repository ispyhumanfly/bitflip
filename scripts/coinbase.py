#!python

from coinbase.rest import RESTClient

import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv('COINBASE_API_KEY')
private_key = os.getenv('COINBASE_PRIVATE_KEY')

client = RESTClient(api_key=api_key, api_secret=private_key)
client.get_accounts()
