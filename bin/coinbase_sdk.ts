#!ts-node

import { Coinbase, Wallet } from "@coinbase/coinbase-sdk";
import * as dotenv from "dotenv";

dotenv.config();

Coinbase.configure({ apiKeyName: process.env.COINBASE_API_KEY!, privateKey: process.env.COINBASE_PRIVATE_KEY! });

((async () => {

    let wallet = await Wallet.listWallets()
    console.log(wallet)

}))();
