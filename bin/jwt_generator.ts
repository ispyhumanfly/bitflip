#!ts-node

const { sign } = require("jsonwebtoken");
const crypto = require("crypto");
import * as dotenv from "dotenv";

dotenv.config();

const key_name = process.env.COINBASE_API_KEY!;
const key_secret = process.env.COINBASE_PRIVATE_KEY!;

const request_method = "GET";
const url = "api.coinbase.com";
const request_path = "/api/v3/brokerage/accounts";

const algorithm = "HS256";
const uri = request_method + " " + url + request_path;

const token = sign(
  {
    iss: "cdp",
    nbf: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 120,
    sub: key_name,
    uri,
  },
  key_secret,
  {
    algorithm,
    header: {
      kid: key_name,
      nonce: crypto.randomBytes(16).toString("hex"),
    },
  }
);
console.log(token);