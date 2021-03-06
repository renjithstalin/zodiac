#!/bin/bash
echo "<h2>Libra Infrastructure</h2>" >> deployment-log.html
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo         Deploying Libra
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ---Global Variables
echo "LIBRA_ALIAS: $LIBRA_ALIAS"
echo "DEFAULT_LOCATION: $DEFAULT_LOCATION"
echo "OUTPUT: $OUTPUT"
echo
# set local variables
# Derive as many variables as possible
applicationName="${LIBRA_ALIAS}"
resourceGroupName="${applicationName}-rg"
storageAccountName=${applicationName}$RANDOM
functionAppName="${applicationName}-func"

echo "LIMONE_ALIAS: $LIMONE_ALIAS"
limoneApplicationName="${LIMONE_ALIAS}"
limoneResourceGroupName="${limoneApplicationName}-rg"
limoneServiceBusNamespace="${limoneApplicationName}sb"
limoneServiceBusConnectionString=$(az servicebus namespace authorization-rule keys list -g $limoneResourceGroupName --namespace-name $limoneServiceBusNamespace -n RootManageSharedAccessKey --query 'primaryConnectionString' -o tsv)

# limone application insights info
limoneWebAppName=$limoneApplicationName-api
limoneAIKey=$(az monitor app-insights component show --app $limoneWebAppName -g $limoneResourceGroupName --query instrumentationKey -o tsv)


echo ---Derived Variables
echo "Application Name: $applicationName"
echo "Resource Group Name: $resourceGroupName"
echo "Storage Account Name: $storageAccountName"
echo "Function App Name: $functionAppName"
echo

echo "Creating resource group $resourceGroupName in $DEFAULT_LOCATION"
az group create -l "$DEFAULT_LOCATION" --n "$resourceGroupName" --tags  ZodiacInstance=$ZODIAC_INSTANCE Application=zodiac MicrososerviceName=libra MicroserviceID=$applicationName PendingDelete=true >> deployment-log.html
echo "<p>Resource Group: $resourceGroupName</p>" >> deployment-log.html

echo "Creating storage account $storageAccountName in $resourceGroupName"
az storage account create \
--name $storageAccountName \
--location $DEFAULT_LOCATION \
--resource-group $resourceGroupName \
--sku Standard_LRS >> deployment-log.html
echo "<p>Storage Account: $storageAccountName</p>" >> deployment-log.html

echo "Creating function app $functionAppName in $resourceGroupName"
echo "<p>Function App: $functionAppName</p>" >> deployment-log.html
echo "<p>Function App Settings:" >> deployment-log.html
az functionapp create \
 --name $functionAppName \
 --storage-account $storageAccountName \
 --consumption-plan-location $DEFAULT_LOCATION \
 --resource-group $resourceGroupName \
 --functions-version 3 \
 --app-insights $limoneWebAppName \
 --app-insights-key $limoneAIKey >> deployment-log.html
echo "</p>" >> deployment-log.html
 
echo "Updating App Settings for $functionAppName"
settings="ServiceBusConnection=$limoneServiceBusConnectionString"
echo "<p>Function App Settings:" >> deployment-log.html
az webapp config appsettings set -g $resourceGroupName -n $functionAppName --settings "$settings"  >> deployment-log.html
echo "</p>" >> deployment-log.html
