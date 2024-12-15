#!python

from prefect import flow, task
import subprocess

@task(log_prints=True)
def execute_bitfinex_raku():
    try:
        result = subprocess.run(['raku', 'scripts/bitfinex.raku'], 
                              capture_output=True, 
                              text=True, 
                              check=True)
        print(f"Bitfinex ETH check completed: {result.stdout}")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing bitfinex.raku: {e.stderr}")
        raise e

@flow(name="Check ETH Bitfinex")
def check_eth_bitfinex():
    execute_bitfinex_raku()

# run the flow!
if __name__=="__main__":
    check_eth_bitfinex.serve(
        name="check-eth-bitfinex-minute",
        cron="* * * * *",  # Run every minute
    )