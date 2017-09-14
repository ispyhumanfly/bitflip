import * as poloniex from "poloniex.js"

const poloniex = new Poloniex()

poloniex.returnMarginAccountSummary((err, data) => {
    if (err){
        // handle error
    }

    console.log(data);
})