
import * as Gdax from "gdax"
import * as process from "process"

const API_KEY = process.env.BITFLIP_COINBASE_PRO_APIKEY
const API_SECRET = process.env.BITFLIP_COINBASE_PRO_APISECRET

const publicClient = new Gdax.PublicClient()

const myCallback = (err, response, data) => {
    console.log(data)
}

publicClient.getProducts(myCallback)

/*
const key = 'your_api_key';
const secret = 'your_b64_secret';
const passphrase = 'your_passphrase';
 
const apiURI = 'https://api.gdax.com';
const sandboxURI = 'https://api-public.sandbox.gdax.com';
 
const authedClient = new Gdax.AuthenticatedClient(
  key,
  secret,
  passphrase,
  apiURI
);*/