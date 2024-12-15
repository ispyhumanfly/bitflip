#!raku

use HTTP::UserAgent;
use JSON::Fast;
use MIME::Base64;
use Crypt::Hmac;
use Crypt::Hmac::SHA256;

use Env::Dotenv :ALL;

dotenv_load();

my $apiKey = 'YOUR_COINBASE_API_KEY';
my $apiSecret = 'YOUR_COINBASE_API_SECRET';
my $apiUrl = 'https://api.pro.coinbase.com';

my $currencyPair = 'BTC-USDC';
my $sellThreshold = 0.5;  # 50% drop threshold

sub create-signature(Int $timestamp, Str $method, Str $path, Str $body) returns Str {
    my $what = $timestamp ~ $method ~ $path ~ $body;
    my $key = MIME::Base64.decode($apiSecret);
    my $hmac = Crypt::Hmac.new('SHA256', :key($key));
    return $hmac.hmac($what).b64encode;
}

sub get-account-balance() returns Numeric {
    my $timestamp = time;
    my $method = 'GET';
    my $path = '/accounts';
    my $body = '';

    my $signature = create-signature($timestamp, $method, $path, $body);

    my %headers = (
        'CB-ACCESS-KEY' => $apiKey,
        'CB-ACCESS-SIGN' => $signature,
        'CB-ACCESS-TIMESTAMP' => $timestamp,
        'CB-ACCESS-PASSPHRASE' => '',
    );

    my $ua = HTTP::UserAgent.new;
    my $response = $ua.get($apiUrl ~ $path, :headers(%headers));

    if $response.is-success {
        my $accounts = from-json($response.content);
        my $btcAccount = $accounts.grep({ .<currency> eq 'BTC' }).first;

        if $btcAccount {
            return $btcAccount<available>.Numeric;
        }
        else {
            die 'BTC account not found.';
        }
    }
    else {
        die "Failed to get account balance: $response.status $response.content";
    }
}

sub get-btc-price() returns Numeric {
    my $response = HTTP::UserAgent.new.get($apiUrl ~ "/products/$currencyPair/ticker");

    if $response.is-success {
        my $data = from-json($response.content);
        return $data<price>.Numeric;
    }
    else {
        die "Failed to get BTC price: $response.status $response.content";
    }
}

sub sell-btc(Numeric $amount) {
    my $timestamp = time;
    my $method = 'POST';
    my $path = '/orders';
    my $body = to-json({
        'type' => 'market',
        'side' => 'sell',
        'product_id' => $currencyPair,
        'size' => $amount.Str,
    });

    my $signature = create-signature($timestamp, $method, $path, $body);

    my %headers = (
        'CB-ACCESS-KEY' => $apiKey,
        'CB-ACCESS-SIGN' => $signature,
        'CB-ACCESS-TIMESTAMP' => $timestamp,
        'CB-ACCESS-PASSPHRASE' => '',
        'Content-Type' => 'application/json',
    );

    my $ua = HTTP::UserAgent.new;
    my $response = $ua.post($apiUrl ~ $path, :headers(%headers), :content($body));

    if $response.is-success {
        say "Sold $amount BTC into USDC.";
    }
    else {
        die "Failed to sell BTC: $response.status $response.content";
    }
}

sub monitor-btc-price() {
    my @prices;
    my $priceHistoryDays = 7;
    my $priceHistorySize = 24 * $priceHistoryDays;  # 24 hours * number of days

    while True {
        my $btcPrice = get-btc-price();
        @prices.push($btcPrice);

        if @prices.elems > $priceHistorySize {
            @prices.shift;  # Remove oldest price
        }

        if @prices.elems >= $priceHistorySize {
            my $averagePrice = @prices.sum / $priceHistorySize;
            my $thresholdPrice = $averagePrice * (1 - $sellThreshold);

            if $btcPrice <= $thresholdPrice {
                my $btcBalance = get-account-balance();
                if $btcBalance > 0 {
                    sell-btc($btcBalance);
                }
            }
        }

        # Sleep for 1 hour
        sleep 3600;
    }
}

monitor-btc-price();
