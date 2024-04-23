# Azure Virtual Machine 

## Simple Demo

### Create a resource group

~~~bash
prefix=cptdazvm
location=germanywestcentral
az group create -n $prefix -l $location
~~~

### Create the Azure Infrastructure

Create Azure infra resources via Azure Bicep Resource Templates and Azure CLI.

Use the flag `--what-if` to simulate the deployment without actually creating the resources.

~~~bash
adminPassword='demo!pass123!'
adminUsername='chpinoto'
az deployment group create -g $prefix -w -n ${prefix}dep1 -p prefix=$prefix location=$location adminPassword=$adminPassword adminUsername=$adminUsername -f ./step1/deploy.bicep
~~~

Create the Azure infra resources via Azure Bicep Resource Templates and Azure CLI.

~~~bash
az deployment group create -g $prefix -n ${prefix}dep1 -p prefix=$prefix location=$location adminPassword=$adminPassword adminUsername=$adminUsername -f ./step1/deploy.bicep
~~~

### Log into VM via Bastion with SSH and local user

~~~bash
# login to the VM with local user:
az vm show -g $prefix -n $prefix
az vm show -g $prefix -n $prefix --query id -o tsv
vmId=$(az vm show -g $prefix -n $prefix --query id -o tsv)
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmId --auth-type password --username $adminUsername
demo!pass123!
~~~

Inside the VM we will verify if cloud-init did its job.

~~~bash
ls # should list both files test1.txt and test2.txt
cat test1.txt # should print "Hello World"
cat test2.txt # should printe the date the file has been created.
# verify the cloud init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
grep test2.txt /var/log/cloud-init.log
ls /var/lib/cloud/instances/ # file 579c8312-a764-db42-83bd-6a1bf74a917c
sudo cat /var/lib/cloud/instances/579c8312-a764-db42-83bd-6a1bf74a917c/cloud-config.txt 
logout
~~~

### Log into VM via Bastion with SSH and Entra ID User (AAD User)


Join the VM to Entra ID (Azure AD) via the VM extension AADSSHLoginForLinux. 

Create the Azure infra resources via Azure Bicep Resource Templates and Azure CLI.

~~~bash
currentUserObjectId=$(az ad signed-in-user show --query id -o tsv)
az deployment group create -g $prefix -n ${prefix}dep2 -p prefix=$prefix location=$location userObjectId=$currentUserObjectId -f ./step2/deploy.bicep
~~~

Log into the VM via Bastion with our current user

~~~bash
az account show --query user
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmId --auth-type AAD
whoami
logout
~~~

### Execute a script on the VM via Azure CLI

~~~bash
az vm run-command invoke -g $prefix -n $prefix --command-id RunShellScript --scripts "echo 'Hello from Azure CLI' + $(date)"
~~~

### Execute a script via Azure Deployment Script

The Custom Script Extension Version 2 downloads and runs scripts on Azure virtual machines (VMs). Use this extension for post-deployment configuration, software installation, or any other configuration or management task. You can download scripts from Azure Storage or another accessible internet location, or you can provide them to the extension runtime.

~~~bash
az deployment group create -g $prefix -n ${prefix}dep3 -p prefix=$prefix location=$location -f ./step3/deploy.bicep
~~~

Log into the VM via Bastion with our current user

~~~bash
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmId --auth-type AAD
ls /home/chpinoto
cat /home/chpinoto/test3.txt
logout
~~~

### Restrict network access of the VM via Network Security Group

Log into the VM via Bastion with our current user

~~~bash
az network bastion ssh -n $prefix -g $prefix --target-resource-id $vmId --auth-type AAD
curl -Iv https://www.heise.de
logout
~~~

Open new shell and deploy NSG

~~~bash 
prefix=cptdazvm
location=germanywestcentral
az deployment group create -g $prefix -n ${prefix}dep4 -p prefix=$prefix location=$location -f ./step4/deploy.bicep
~~~

### Clean up

~~~bash
az group delete -n $prefix -y
~~~

Back on the VM we will verify the network restrictions

~~~bash
curl -Iv https://www.heise.de
logout
~~~

### Git

~~~bash
git init main
gh repo create $prefix --public
git remote add origin https://github.com/cpinotossi/$prefix.git
git remote -v
git status
git add .
git commit -m"init"
git push origin master

git tag //list local repo tags
git ls-remote --tags origin //list remote repo tags
git fetch --all --tags // get all remote tags into my local repo
git log --oneline --decorate // List commits
git log --pretty=oneline //list commits
git tag -a v2 b20e80a //tag my last commit

git checkout v1
git switch - //switch back to current version
co //Push all my local tags
git push origin <tagname> //Push a specific tag
git commit -m"not transient"
git tag v1
git push origin v1
git tag -l
git fetch --tags
git clone -b <git-tagname> <repository-url> 
~~~