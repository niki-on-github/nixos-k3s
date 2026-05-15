#!/bin/sh
set -e

# Validate required environment variables
for VAR in GARAGE_ADMIN_TOKEN GARAGE_HOST GARAGE_ZONE GARAGE_CAPACITY; do
  if [ -z "$(eval echo \$$VAR)" ]; then
    echo "Error: Required environment variable $VAR is not set"
    exit 1
  fi
done

echo "Waiting for Garage cluster to be ready..."
sleep 20

# Function to get node ID from metrics
get_node_id() {
  HOST=$1
  URL="http://$HOST:3903/v2/GetNodeInfo?node=self"
  while true; do
    # Call the admin API and parse the node ID
    RESPONSE=$(wget -q -O - \
      --header "Authorization: Bearer $GARAGE_ADMIN_TOKEN" \
      "$URL" 2>/dev/null)
    ID=$(printf '%s' "$RESPONSE" | sed -n -E 's/.*"nodeId":\s*"([a-fA-F0-9]+)".*/\1/p' | head -n 1)

    if [ -n "$ID" ]; then
      echo "$ID"
      return 0
    fi
    echo "Waiting for $HOST to be ready..."
    sleep 5
  done
}

# Resolve Coordinator
echo "Resolving coordinator $GARAGE_HOST..."
COORD_ID=$(get_node_id $GARAGE_HOST)
echo "Coordinator ID: $COORD_ID"
GARAGE_RPC_HOST="$COORD_ID@$GARAGE_HOST:3901"

run_garage() {
  /shared/garage -h $GARAGE_RPC_HOST "$@"
}

# Layout configuration
echo "Configuring layout..."
run_garage layout assign -z $GARAGE_ZONE -c $GARAGE_CAPACITY $COORD_ID || true
run_garage layout show

CURRENT_VERSION=$(run_garage layout show | grep "Current cluster layout version" | awk '{print $5}')
if [ ! -z "$CURRENT_VERSION" ]; then
   NEXT_VERSION=$((CURRENT_VERSION + 1))
   echo "Applying layout version $NEXT_VERSION"
   run_garage layout apply --version $NEXT_VERSION || true
else
   run_garage layout apply || true
fi

# Import key (optional - requires all 3 key env vars)
if [ -n "$GARAGE_KEY_ID" ] && [ -n "$GARAGE_SECRET_KEY" ] && [ -n "$GARAGE_KEY_NAME" ]; then
  echo "Importing key $GARAGE_KEY_ID ($GARAGE_KEY_NAME)..."
  
  if ! echo "$GARAGE_KEY_ID" | grep -qE '^GK[0-9a-fA-F]{24}$'; then
    echo "ERROR: Invalid key ID format: '$GARAGE_KEY_ID'. Key ID must start with 'GK' followed by 24 hex characters"
    exit 1
  fi
  
  if ! echo "$GARAGE_SECRET_KEY" | grep -qE '^[0-9a-fA-F]{64}$'; then
    echo "ERROR: Invalid secret key format. Secret key must be 64 hex characters (32 bytes)"
    exit 1
  fi
  
  run_garage key import "$GARAGE_KEY_ID" "$GARAGE_SECRET_KEY" --yes -n "$GARAGE_KEY_NAME" || true
fi

if [ -n "$GARAGE_BUCKETS" ]; then
  for BUCKET in $(echo "$GARAGE_BUCKETS" | tr ',' ' '); do
    echo "create bucket $BUCKET"
    run_garage bucket create "$BUCKET" 2>/dev/null || true
    run_garage bucket website --allow "$BUCKET" 2>/dev/null || true
    if [ -n "$GARAGE_KEY_ID" ]; then
      run_garage bucket allow "$BUCKET" --key "$GARAGE_KEY_ID" --read --write || true
    fi
  done
fi
