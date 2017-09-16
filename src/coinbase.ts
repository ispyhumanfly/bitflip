#!/usr/local/bin/ts-node -F

import * as coinbase from "coinbase"
import * as math from "coin-math"
import * as process from "process"

const API_KEY = process.env.COINBASE_APIKEY
const API_SECRET = process.env.COINBASE_APISECRET

let client = new coinbase.Client({'apiKey': API_KEY, 'apiSecret': API_SECRET})

client.getAccounts({}, (err, accounts) => {

    if (err) console.log(err)

    accounts.forEach(account => {

         if (account.name === 'BTC Wallet') {

            // Getting the balance amount.

            let amount: number = account.balance.amount

            // Listing all of its transactions.

            /* account.getTransactions(null,(err, txns) => {
                    txns.forEach(txn => {
                    console.log('my txn status: ' + txn.details.title)
                })
            }) */

            // Send money to another wallet.

            account.requestMoney({'to': 'jenkraydich@gmail.com',
                                'amount': '0.11380',
                                'currency': 'BTC',
                                'idem': '9316dd16-0c5'}, function(err, tx) {
                console.log(tx)
            });

            console.log(account.name)
            console.log(math.floatToFixed(amount, true, true))
            console.log(amount)
        }
  })
})

