import * as poloniex from "poloniex.js"

poloniex.returnMarginAccountSummary((err, data) => {
    if (err){
        // handle error
    }

    console.log(data);
})