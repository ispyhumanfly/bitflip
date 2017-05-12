#!/usr/local/bin/ts-node -F

import * as coinbase from "coinbase"
import * as math from "coin-math"
import * as process from "process"

let client = new coinbase.Client({'apiKey': process.env.COINBASE_APIKEY, 'apiSecret': process.env.COINBASE_APISECRET})

client.getAccounts({}, (err, accounts) => {
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

            /* account.sendMoney({'to': '1HFsfuU9J541atL5SXT9iYeRwzJuS4tTeB',
                                'amount': '0.019',
                                'currency': 'BTC',
                                'idem': '9316dd16-0c5'}, function(err, tx) {
                console.log(tx);
            }); */

            console.log(account.name)
            console.log(math.floatToFixed(amount, true, true))
            console.log(amount)
        }
  })
})

