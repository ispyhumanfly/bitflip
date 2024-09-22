#!raku

use v6;
use HTTP::UserAgent;
use JSON::Fast;

use Env::Dotenv :ALL;

dotenv_load();

my $api-key = %*ENV<POLYGON_API_KEY>;
my @symbols = <AAPL MSFT TSLA>; # Array of stock ticker symbols to monitor

# Function to get related companies for a given ticker
sub get-related-companies($ticker) {
    my $url = "https://api.polygon.io/v1/related-companies/$ticker?apiKey=$api-key";
    my $ua = HTTP::UserAgent.new;
    my $response = $ua.get($url);

    if $response.is-success {
        my $data = from-json($response.content);
        return $data<results>;
    } else {
        die "Request failed with status " ~ $response.status-line;
    }
}

# Function to get details for a specific ticker
sub get-ticker($ticker) {
    my $url = "https://api.polygon.io/v3/reference/tickers?ticker=$ticker&apiKey=$api-key";
    my $ua = HTTP::UserAgent.new;
    my $response = $ua.get($url);

    if $response.is-success {
        my $data = from-json($response.content);
        return $data;
    } else {
        die "Request failed with status " ~ $response.status-line;
    }
}

# Monitor the specified stock ticker symbols
for @symbols -> $symbol {
    say "Checking related companies for $symbol...";
    my $related-companies = get-related-companies($symbol);
    say "Related companies for $symbol: ", $related-companies.join(', ');


    # Example usage of get-ticker
    say "Fetching details for $symbol...";
    my $ticker-details = get-ticker($symbol);
    say "Ticker details for $symbol: ", $ticker-details.perl;

}


# Keep the program running
react whenever Promise.in(1) {}