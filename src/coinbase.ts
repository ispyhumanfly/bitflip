#!/usr/bin/env ts-node

import * as coinbase from "coinbase"
import * as math from "coin-math"
import * as process from "process"

const API_KEY = process.env.BITFLIP_COINBASE_APIKEY
const API_SECRET = process.env.BITFLIP_COINBASE_APISECRET

let client = new coinbase.Client({'apiKey': API_KEY, 'apiSecret': API_SECRET,    strictSSL: false
})

client.getAccounts({}, (err, accounts) => {

    if (err) console.log(err)

    accounts.forEach(account => {

         if (account.name) {

            // Getting the balance amount.

            let amount: number = account.balance.amount
            console.log(`${account.name} has ${amount}`)

            // Listing all of its transactions.

            account.getTransactions(null,(err, txns) => {
                    
                txns.forEach(txn => {
                    
                    console.log('my txn title: ' + txn.details.title)
                    console.log('native_amount: ' + txn.native_amount.amount)

                })
            })

            // List buys...
            account.getBuys(null, (err, txs) => {

                txs.forEach(buy => {
                
                    console.log(buy.total)
                })
            })

            // Send money to another wallet.

            /* account.requestMoney({'to': 'jane-doe@gmail.com',
                                'amount': '0.11380',
                                'currency': 'BTC',
                                'idem': '9316dd16-0c5'}, function(err, tx) {
                console.log(tx)
            });*/

            /* console.log(account.name)
            console.log(math.floatToFixed(amount, true, true))
            console.log(amount) */
        }
  })
})

