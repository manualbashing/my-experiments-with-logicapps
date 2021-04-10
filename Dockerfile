FROM mcr.microsoft.com/azure-functions/node:3.0-node12

ENV AzureWebJobsStorage=UseDevelopmentStorage=true
ENV AZURE_FUNCTIONS_ENVIRONMENT Development
ENV AzureWebJobsScriptRoot=/home/site/wwwroot
ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true
ENV FUNCTIONS_V2_COMPATIBILITY_MODE=true

WORKDIR /home/site/wwwroot
COPY host.json .
COPY proxies.json .
COPY TheCatApp TheCatApp/
COPY StatelessHello StatelessHello/