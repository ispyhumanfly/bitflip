#!raku

use HTTP::UserAgent;
use JSON::Fast;
use OpenSSL::HMAC;
use MIME::Base64;

my $api-key = 'your_api_key';
my $api-secret = 'your_api_secret';
my $passphrase = 'your_passphrase';
my $api-url = 'https://api.pro.coinbase.com';

# Helper function to get the current timestamp
sub get-timestamp {
    return DateTime.now.posix;
}

# Generate API signature for authentication
sub generate-signature($timestamp, $method, $request-path, $body = '') {
    my $what = $timestamp ~ $method ~ $request-path ~ $body;
    my $key = decode-base64($api-secret);
    my $hmac = hmac($what.encode('utf-8'), $key, 'sha256');
    return encode-base64($hmac, '');
}

# Function to make a signed API request
sub make-request($method, $path, $body = '') {
    my $timestamp = get-timestamp;
    my $signature = generate-signature($timestamp, $method, $path, $body);

    my $ua = HTTP::UserAgent.new;
    my %headers = (
        'CB-ACCESS-KEY' => $api-key,
        'CB-ACCESS-SIGN' => $signature,
        'CB-ACCESS-TIMESTAMP' => $timestamp,
        'CB-ACCESS-PASSPHRASE' => $passphrase,
        'Content-Type' => 'application/json',
    );

    my $url = $api-url ~ $path;
    my $response = $method eq 'GET'
        ?? $ua.get($url, :headers(%headers))
        !! $ua.post($url, :content($body), :headers(%headers));

    if $response.is-success {
        return from-json($response.content);
    } else {
        die "Request failed with status " ~ $response.status-line;
    }
}

# Example usage: Get historical prices for BTC-USD
sub get-historical-data($granularity) {
    my $path = "/products/BTC-USD/candles?granularity=$granularity";
    return make-request('GET', $path);
}

# Example call
say get-historical-data(3600);