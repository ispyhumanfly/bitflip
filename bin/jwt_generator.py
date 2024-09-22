#!python

import os
from coinbase import jwt_generator
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.environ.get("COINBASE_API_KEY")
API_SECRET = os.environ.get("COINBASE_API_SECRET")

request_method = "GET"
request_path = "/api/v3/brokerage/accounts"

def main():
    jwt_uri = jwt_generator.format_jwt_uri(request_method, request_path)
    jwt_token = jwt_generator.build_rest_jwt(jwt_uri, API_KEY, API_SECRET)
    print(jwt_token)

if __name__ == "__main__":
    main()