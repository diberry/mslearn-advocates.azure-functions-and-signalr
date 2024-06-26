# To use the Microsoft Learn Sandbox in the training module
# https://learn.microsoft.com/training/modules/automatic-update-of-a-webapp-using-azure-functions-and-signalr
# To run: sign in to Azure CLI with `az login`
set -e

# Check if user is logged into Azure CLI
if ! az account show &> /dev/null
then
  echo "You are not logged into Azure CLI. Please log in with 'az login' and try again."
  exit 1
fi
echo "User logged in"

NODE_ENV_FILE="./.env"

# Get the default subscription
SUBSCRIPTION_NAME=$(az account show --query 'name' -o tsv)
echo "Using default subscription: $SUBSCRIPTION_NAME"

# Set the resource group name
RESOURCE_GROUP_NAME="stock-prototype"


RESOURCE_GROUP_NAME=$(az group list --query '[0].name' -o tsv)
echo "Using resource group $RESOURCE_GROUP_NAME"

export STORAGE_ACCOUNT_NAME=signalr$(openssl rand -hex 5)
export COMSOSDB_NAME=signalr-cosmos-$(openssl rand -hex 5)

echo "Subscription Name: $SUBSCRIPTION_NAME"
echo "Resource Group Name: $RESOURCE_GROUP_NAME"
echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "CosmosDB Name: $COMSOSDB_NAME"

echo "Creating Storage Account"

az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --kind StorageV2 \
  --sku Standard_LRS

echo "Creating CosmosDB Account"

  az cosmosdb create  \
  --name $COMSOSDB_NAME \
  --resource-group $RESOURCE_GROUP_NAME

echo "Get storage connection string"

STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
--name $(az storage account list \
  --resource-group $RESOURCE_GROUP_NAME \
  --query [0].name -o tsv) \
--resource-group $RESOURCE_GROUP_NAME \
--query "connectionString" -o tsv)

echo "Get account name" 

COSMOSDB_ACCOUNT_NAME=$(az cosmosdb list \
    --resource-group $RESOURCE_GROUP_NAME \
    --query [0].name -o tsv)

echo "Get CosmosDB connection string"

COSMOSDB_CONNECTION_STRING=$(az cosmosdb keys list --type connection-strings \
  --name $COSMOSDB_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --query "connectionStrings[?description=='Primary SQL Connection String'].connectionString" -o tsv)

printf "\n\nReplace <STORAGE_CONNECTION_STRING> with:\n$STORAGE_CONNECTION_STRING\n\nReplace <COSMOSDB_CONNECTION_STRING> with:\n$COSMOSDB_CONNECTION_STRING"

# create a .env file with the connection strings and keys
cat >> $NODE_ENV_FILE <<EOF2
STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING
COSMOSDB_CONNECTION_STRING=$COSMOSDB_CONNECTION_STRING
EOF2

# put resource group name in .env file
echo -e "\nRESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME" >> $NODE_ENV_FILE
echo "\n\nRESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME"


# Validate the .env file
if [ -f "$NODE_ENV_FILE" ]; then
  echo "\n\nThe .env file was created successfully."
else
  echo "\n\nThe .env file was not created."
fi