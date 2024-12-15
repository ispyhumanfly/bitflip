#!raku

use HTTP::UserAgent;
use JSON::Fast;

my $client = HTTP::UserAgent.new(
    default-header => {
        'User-Agent' => 'Bitflip HTTP Client',
    }
);

# Example function to get ticker information
sub get-ticker-info($symbol) {
    try {
        my $response = $client.get("https://api-pub.bitfinex.com/v2/ticker/$symbol");
        if $response.is-success {
            say to-json(from-json($response.content), :pretty);
        } else {
            die "Error fetching ticker information for $symbol: {$response.status-line}";
        }
    }
    CATCH {
        default {
            say "Error fetching ticker information for $symbol: $_";
        }
    }
}

# Example usage
get-ticker-info('tETHUSD');  # Fetch ticker information for BTC/USD