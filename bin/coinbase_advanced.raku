#!raku

use HTTP::UserAgent;
use JSON::Fast;
use Env::Dotenv :ALL;
use Shell::Command;
use Base64;

dotenv_load;

my $api-key = %*ENV<COINBASE_API_KEY>;
my $api-secret = %*ENV<COINBASE_PRIVATE_KEY>;

my $request-method = 'GET';
my $url = 'api.coinbase.com';
my $request-path = '/v2/accounts';

my $algorithm = 'ES256';
my $uri = "$request-method $url$request-path";

my $header = {
    alg => $algorithm,
    kid => $api-key,
    nonce => run("openssl rand -hex 16", :out).out.slurp.trim
};

my $payload = {
    iss => 'cdp',
    nbf => (now.Int / 1000).floor,
    exp => (now.Int / 1000).floor + 120,
    sub => $api-key,
    uri => $uri,
};

sub base64url-encode(Str $data) {
    return encode-base64($data.encode('utf-8'), :uri).subst(/'='*$/, '');
}

my $header-json = to-json($header);
my $payload-json = to-json($payload);

my $header-base64 = base64url-encode($header-json);
my $payload-base64 = base64url-encode($payload-json);

# Generate the signature using OpenSSL
# Write the secret to a temporary file
my $temp-secret-file = "temp_secret.pem";
spurt $temp-secret-file, $api-secret;
$api-secret.say;

my $signature-base64 = run(
    "echo -n '$header-base64.$payload-base64' | openssl dgst -sha256 -sign $temp-secret-file | openssl base64 -A",
    :out
).out.slurp.trim.subst('+', '-').subst('/', '_').subst(/'='*$/, '');

# Clean up the temporary file
unlink $temp-secret-file;

my $token = "$header-base64.$payload-base64.$signature-base64".subst(/\s+/, '', :g);

say "export JWT=$token";

# remove all whitespace from $token
$token = $token.subst(/\s+/, '', :g);

say "export JWT=$token";

my $client = HTTP::UserAgent.new(
    default-header => {
        'CB-ACCESS-KEY' => $api-key,
        'CB-ACCESS-SECRET' => $api-secret,
        'CB-ACCESS-SIGN' => $token,
        'CB-ACCESS-TIMESTAMP' => (now.Int / 1000).Str,
        'Content-Type' => 'application/json',
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3' }
);

# Example function to get account information
sub get-account-info {
    try {
        "hi".say;
        my $response = $client.get('https://api.exchange.coinbase.com/accounts');
        $response.say;
        if $response.is-success {
            say to-json(from-json($response.content), :pretty);
        } else {
            die "Error fetching account information: {$response.status-line}";
        }
    }
    CATCH {
        default {
            say "Error fetching account information: $_";
        }
    }
}

# Example function to get ticker information
sub get-ticker-info($ticker) {
    try {
        my $response = $client.get("https://api.exchange.coinbase.com/products/$ticker/ticker");
        if $response.is-success {
            say to-json(from-json($response.content), :pretty);
        } else {
            die "Error fetching ticker information for $ticker: {$response.status-line}";
        }
    }
    CATCH {
        default {
            say "Error fetching ticker information for $ticker: $_";
        }
    }
}

# Example usage
get-account-info();
#get-ticker-info('BTC-USD');