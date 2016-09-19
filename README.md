# hub_powershell_api_example


## Intro

this is an example to show how you can use the REST api of Blackducksoftware hub.\n


## How to use
Steps to take:

1. start a powershell
2. cd to a directory where you want to put this example
3. clone the project
`git clone https://github.com/blackducksoftware/hub_powershell_api_example.git` 
4. cd hub_powershell_api_example
5. The following options are available to change via script parameters:
    * serverUrl - The full url of the hub server (This is required)
        - http://localhost:8080
        - http://myhubserver.example.com
        - https://hub.example.com
    * username - The username of the hub user to user (This is required)
    * password - This password of the hub user (This is optional, will be prompted if omitted)
    * curlCmd - If you need to use a different curl cmd than provided

6. run the poweshell script 
`./hubProjects.ps1 -server http://myhubserver.example.com -username myuser` `` 

