![Miyagi](https://upload.wikimedia.org/wikipedia/en/2/2e/Pat-Morita_(Karate_Kid).jpg)

*\- Coding always last answer to problem*. (**Mr Miyagi on Logic Apps**)

# DevOps with Logic Apps - From Awful to Awesome

These are the notes to my session at Azure Global Bootcamp 2021: [https://globalazure.net/sessions/253953](https://globalazure.net/sessions/253953)

## LogicApps v1

- [Azure Logic Apps  v1](https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-overview): Low Code / No Code Workflow Service 

Useful use cases: 

- Send email before keys or secrets in [key vaults](https://docs.microsoft.com/en-us/azure/key-vault/general/overview) expire
- Start/stop vms
- Build [Chocolatey ](https://chocolatey.org/) package once a new binary is uploaded (trigger an azure devops pipeline)
- Simple aggregation and transformation of API responses

### Development Flow

- Development only web based designer (recipe for desaster)
- Use web based desginer + Visual Studio Code and export any significant change (cumbersome)
- Use Visual Studio with the integrated Designer (sorry Linux folks)

**Not awesome**:

- Whatever you do, you are working directly on Azure. 
- To test any any change you need to redeploy to your testing environment
- You version control only the exported arm templates 
- What if more than one developer is working on a Logic App? 
- You might want to create an azure resource for each developer

  - => Your ARM templates will always diverge, because they also describe the azure resource (not a problem in Visual Studio)
  - Visual Studio is fine, but a lot of other commin services can be perfectly developed in vscode.. Switch IDE only for one part of the solution? What if your os is Linux?


### Build and Deploy with Azure Pipelines

- You can use a step in Azure pipeline to deploy arm templates
- Terraform works as well if the arm is limited to the logic app
  - use the new resource type:  [resource_group_template_deployment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment)
  - The old one `azurerm_template_deployment` acts funny in some situations

Not awesome:

- You have to be very careful with the exported arm templates. If several apps are used for testing, the names of the input parameters might change
- This is a bit better with Visual Studio or Jeff Hollan's LogicAppTemplateCreator PowerShell module ([GitHub - jeffhollan/LogicAppTemplateCreator: Script to convert Logic Apps into templates for deployment](https://github.com/jeffhollan/LogicAppTemplateCreator)). Still the names of the connection objects become part of the parameter name. Might make it necessary to normalize parameter names before deployment
- There is no separation between deploying the Logic App resource and deploying workflow code.. At what stage do you deploy your Logic App arm template?


OK all of this is manageble and not outright awful.. But also not awesome.

## Logic Apps v2

- Logic Apps v2 Single tenant approach: One logic app hosts one or more workflows (shared resources)
- Sits on top of the Azure Functions runtime

## Development Flow

- Visual Studio Code
- Local testing and debugging!
- See the run history locally too
- Deployment Slots!
- Configuration variables!
  - No need anymore to redeploy all logic apps that share one particular configuration if that configuration is changed. 
  - Change the logic app setting at runtime

### Storage connection for development

Defined in `local.settings.json` (`UseDevelopmentStorage=true`)

**Microsoft Storage Emulator**

- Works but is quite heavy (build on top of a local sql instance)
- No longer actively developed
- Runs only on windows

**Azurite currently not supported**

- Logic Apps will need to create some table settings, which is currently not supported by Azurite V3.

**Using a storage account on Azure dedicated to testing**

- Fine if the Storage Emulator wont work
- Add the connection string to the `local.settings.json`

### Using the designer in vscode over WSL remote connection

- Currently an issue: [When using WSL remote connection, Overview tab is blank · Issue #269 · Azure/logicapps (github.com)](https://github.com/Azure/logicapps/issues/269)

- Still usable, if you get the trigger url via api

```bash
# bash
server=http://localhost:7071
workflowName=TheCatApp
http POST "$server/runtime/webhooks/workflow/api/management/workflows/$workflowName/triggers/manual/listCallbackUrl"
```

- But no way to see the run history

## Build and deploy LogicApps with Azure Pipelines

- DevOps: Like function apps: 
	- Use arm or bicep or terraform to create the resources 
	- build and deploy the workflows that you develop in your IDE
- Proper separation of concerns

## Deploy LogicApps v2 to a docker container

Examples:

- [https://github.com/manualbashing/my-experiments-with-logicapps (github.com)](https://github.com/manualbashing/my-experiments-with-logicapps)
- [logicapps/azure-devops-sample at master · Azure/logicapps (github.com)](https://github.com/Azure/logicapps/tree/master/azure-devops-sample)
- [Tip 311 - How to run Logic Apps in a Docker container | Azure Tips and Tricks (microsoft.github.io)](https://microsoft.github.io/AzureTipsAndTricks/blog/tip311.html)

### Build the image and run the container

```bash
docker build --tag local/logic-app-container .
```

Set your  connection string as parameter  (if you use dedicated storage accont for testing on Azure):

```powershell
# powershell
$connectionString = Read-Host -MaskInput
docker run -d `
  -e WEBSITE_HOSTNAME=localhost `
  -e AzureWebJobsStorage=$connectionString `
  -p 8080:80 `
  local/logic-app-container
```

### Get the trigger URL

Open the storage account and get the value  of `masterKey` from the content of `/azure-webjobs-secrets/{some id}/host.json`

Call the local endpoint to get the correct trigger uri for your workflow

```powershell
# powershell
$masterKey = Read-Host -MaskInput
$workflowName = 'TheCatApp'
$server = 'http://localhost:8080'
$irmSplat = @{
	Method = 'POST' 
	Uri = "$server/runtime/webhooks/workflow/api/management/workflows/$workflowName/triggers/manual/listCallbackUrl?code=$masterKey"
}
$triggerUri = Invoke-RestMethod @irmSplat | Select-Object -ExpandProperty value
$triggerUri = $triggerUri -replace '^https://localhost:443', $server
Write-Host "Trigger for $workflowName: $triggerUri"
```

## Watch this!

- [Logic Apps Talk: DevOps - YouTube](https://www.youtube.com/watch?v=i1vuG67-Sh8&ab_channel=AzureLogicApps)
- [Logic Apps Live - March 2021 - YouTube](https://www.youtube.com/watch?v=mJo-Lr5rZc0&ab_channel=AzureLogicApps)