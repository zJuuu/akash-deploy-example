#!/bin/bash
set -e

AKASH_KEY_NAME=main
AKASH_KEYRING_BACKEND=test

(echo "$AKASH_MNEMONIC") | provider-services keys add $AKASH_KEY_NAME --keyring-backend "$AKASH_KEYRING_BACKEND" --recover --no-backup

AKASH_ACCOUNT_ADDRESS="$(provider-services keys show $AKASH_KEY_NAME -a --keyring-backend $AKASH_KEYRING_BACKEND)"
AKASH_NET="https://raw.githubusercontent.com/akash-network/net/main/mainnet"
AKASH_VERSION="$(curl -s https://api.github.com/repos/akash-network/provider/releases/latest | jq -r '.tag_name')"
AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"
AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | shuf -n 1)"
echo "$AKASH_NODE" "$AKASH_CHAIN_ID" "$AKASH_KEYRING_BACKEND"
AKASH_GAS=auto
AKASH_GAS_ADJUSTMENT=1.5
AKASH_GAS_PRICES=0.025uakt
AKASH_SIGN_MODE=amino-json

provider-services query bank balances --node "$AKASH_NODE" "$AKASH_ACCOUNT_ADDRESS"

DEPLOY_RESULT=$(provider-services tx deployment create deploy.yml --from $AKASH_KEY_NAME --keyring-backend $AKASH_KEYRING_BACKEND --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --gas auto --gas-adjustment $AKASH_GAS_ADJUSTMENT --gas-prices $AKASH_GAS_PRICES --yes -o json)
DSEQ=$(echo "$DEPLOY_RESULT" | jq -r '.logs[0].events[] | select(.type=="akash.v1") | .attributes[] | select(.key=="dseq") | .value' | head -1)
echo "Deployment sequence: $DSEQ"

AKASH_OSEQ=1
AKASH_GSEQ=1
echo "DSEQ: $DSEQ, OSEQ: $AKASH_OSEQ, GSEQ: $AKASH_GSEQ"
echo $AKASH_ACCOUNT_ADDRESS


# Wait for bids to be created
sleep 10

BIDS=$(provider-services query market bid list --owner=$AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $DSEQ --state=open --output json)

echo "$BIDS"

# Extract all providers and their prices, sort by price, and select the cheapest one
AKASH_PROVIDER=$(echo "$BIDS" | jq -r '.bids[] | {provider: .bid.bid_id.provider, price: (.bid.price.amount | tonumber)} | select(.price != null)' | jq -s 'sort_by(.price)[0].provider' | tr -d '"')

echo "Selected provider: $AKASH_PROVIDER"

sleep 5

# Lease the provider - add dseq, gseq, and oseq parameters
provider-services tx market lease create --dseq $DSEQ --provider $AKASH_PROVIDER --from $AKASH_KEY_NAME --node $AKASH_NODE --keyring-backend $AKASH_KEYRING_BACKEND --chain-id $AKASH_CHAIN_ID --gas $AKASH_GAS --gas-adjustment $AKASH_GAS_ADJUSTMENT --gas-prices $AKASH_GAS_PRICES -y

echo "Lease created"

# Confirm lease is active
LEASE=$(provider-services query market lease list --owner=$AKASH_ACCOUNT_ADDRESS --node $AKASH_NODE --dseq $DSEQ --state=active --output json)

echo "$LEASE"

provider-services send-manifest deploy.yml --dseq $DSEQ --provider $AKASH_PROVIDER --from $AKASH_KEY_NAME --keyring-backend $AKASH_KEYRING_BACKEND --node $AKASH_NODE

sleep 20

provider-services lease-status --dseq $DSEQ --from $AKASH_KEY_NAME --provider $AKASH_PROVIDER --keyring-backend $AKASH_KEYRING_BACKEND --node $AKASH_NODE

provider-services lease-logs \
  --dseq "$DSEQ" \
  --provider "$AKASH_PROVIDER" \
  --from "$AKASH_KEY_NAME"

# Close the deployment after 30 seconds
echo "Closing deployment after 30 seconds"
sleep 30

echo "Closing deployment"
provider-services tx deployment close --from $AKASH_KEY_NAME --keyring-backend $AKASH_KEYRING_BACKEND --node $AKASH_NODE --chain-id $AKASH_CHAIN_ID --gas $AKASH_GAS --gas-adjustment $AKASH_GAS_ADJUSTMENT --gas-prices $AKASH_GAS_PRICES -y

echo "Deployment closed"