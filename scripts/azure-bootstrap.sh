#!/usr/bin/env bash
# One-time Azure setup for azure-infra, run in Azure Cloud Shell (Bash):
#
#   curl -fsSL https://raw.githubusercontent.com/external-systems/azure-infra/main/scripts/azure-bootstrap.sh | bash
#
# Creates, in the current subscription:
#   1. a storage account for OpenTofu's state (rg-azure-infra-state,
#      container tfstate, blob versioning and soft delete for 30 days)
#   2. the service principal OpenTofu logs in with (Contributor on the
#      subscription)
# and prints the five values to copy into 1Password. Safe to run again: it
# reuses the storage account and gives the service principal a new secret
# (the old one stops working).
set -euo pipefail

LOCATION="${LOCATION:-southcentralus}"
STATE_RG="${STATE_RG:-rg-azure-infra-state}"
SP_NAME="${SP_NAME:-azure-infra-tofu}"

SUB="$(az account show --query id -o tsv)"
echo "Subscription: $(az account show --query name -o tsv)"

echo "Registering the Azure services this repo uses (takes a minute)..."
for ns in Microsoft.Storage Microsoft.Compute Microsoft.Network Microsoft.SqlVirtualMachine; do
  az provider register --namespace "$ns" --wait -o none
done

echo "State storage..."
az group create -n "$STATE_RG" -l "$LOCATION" -o none
ST="$(az storage account list -g "$STATE_RG" --query '[0].name' -o tsv)"
if [ -z "$ST" ]; then
  ST="tfstate$(od -An -N5 -tx1 /dev/urandom | tr -d ' \n')"
  az storage account create -n "$ST" -g "$STATE_RG" -l "$LOCATION" \
    --sku Standard_GRS --kind StorageV2 --min-tls-version TLS1_2 \
    --allow-blob-public-access false --https-only true -o none
fi
az storage account blob-service-properties update -n "$ST" -g "$STATE_RG" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 30 -o none
KEY="$(az storage account keys list -n "$ST" -g "$STATE_RG" --query '[0].value' -o tsv)"
az storage container create --account-name "$ST" --account-key "$KEY" -n tfstate -o none
unset KEY

echo "Service principal..."
SP="$(az ad sp create-for-rbac --name "$SP_NAME" --role Contributor \
  --scopes "/subscriptions/$SUB" --query '[appId, password, tenant]' -o tsv)"
read -r CLIENT_ID CLIENT_SECRET TENANT_ID <<<"$(echo "$SP" | tr '\n' ' ')"

cat <<OUT

==================== copy these into 1Password ====================
Item azure-service-principal:
  subscription_id:        $SUB
  tenant_id:              $TENANT_ID
  client_id:              $CLIENT_ID
  client_secret:          $CLIENT_SECRET
Item sql-server-settings:
  state_storage_account:  $ST
===================================================================
The client_secret is shown only this once. Clear the screen afterwards:
type  clear  and press Enter.
OUT
