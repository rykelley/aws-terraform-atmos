#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP_NAME="${TFSTATE_RESOURCE_GROUP:-tfstate-homelab}"
LOCATION="${TFSTATE_LOCATION:-eastus2}"
STORAGE_ACCOUNT_NAME="${TFSTATE_STORAGE_ACCOUNT:-homelabue2tfstate}"
CONTAINER_NAME="${TFSTATE_CONTAINER:-tfstate}"

echo "==> Bootstrapping Terraform state backend in Azure"
echo "    Resource Group:   ${RESOURCE_GROUP_NAME}"
echo "    Location:         ${LOCATION}"
echo "    Storage Account:  ${STORAGE_ACCOUNT_NAME}"
echo "    Container:        ${CONTAINER_NAME}"
echo ""

echo "==> Checking Azure CLI login..."
az account show > /dev/null 2>&1 || {
  echo "ERROR: Not logged in to Azure CLI. Run 'az login' first."
  exit 1
}

echo "==> Creating resource group: ${RESOURCE_GROUP_NAME}"
az group create \
  --name "${RESOURCE_GROUP_NAME}" \
  --location "${LOCATION}" \
  --tags ManagedBy=bootstrap Project=homelab-aks

echo "==> Creating storage account: ${STORAGE_ACCOUNT_NAME}"
az storage account create \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${STORAGE_ACCOUNT_NAME}" \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags ManagedBy=bootstrap Project=homelab-aks

echo "==> Enabling blob versioning and soft delete..."
az storage account blob-service-properties update \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30

echo "==> Creating blob container: ${CONTAINER_NAME}"
az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT_NAME}" \
  --auth-mode login

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Update your Atmos stack backend config with:"
echo "  storage_account_name: ${STORAGE_ACCOUNT_NAME}"
echo "  resource_group_name:  ${RESOURCE_GROUP_NAME}"
echo "  container_name:       ${CONTAINER_NAME}"
