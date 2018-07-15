
import * as BFX from "bitfinex-api-node"
import * as process from "process"

const API_KEY = process.env.BITFLIP_BITFINEX_APIKEY
const API_SECRET = process.env.BITFLIP_BITFINEX_APISECRET

const options = {
    version: 2,
    transform: true
}

const client = new BFX(API_KEY, API_SECRET, options).ws

client.on("auth", () => {
    console.log("Bitflip: Authenticated...")
})

client.on("open", () => {

    // Available for Margin Trading.
    client.subscribeTicker("BCHUSD")
    client.subscribeTicker("BTCUSD")
    client.subscribeTicker("DASHUSD")
    client.subscribeTicker("EOSUSD")
    client.subscribeTicker("ETCUSD")
    client.subscribeTicker("ETHUSD")
    client.subscribeTicker("IOTAUSD")
    client.subscribeTicker("LTCUSD")
    client.subscribeTicker("OMGUSD")
    client.subscribeTicker("XMRUSD")
    client.subscribeTicker("ZECUSD")

    // authenticate
    client.auth()
})

client.on("ticker", (pair, coin) => {
    console.log("Pair: " + pair + ", LAST_PRICE:", coin.LAST_PRICE)
})

client.on("error", console.error)
