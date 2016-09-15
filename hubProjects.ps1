<# author : Ton Schoots

 tested on

   Powershell version
   PS C:\Users\tschoots> $PSVersionTable.PSVersion

   Major  Minor  Build  Revision
   -----  -----  -----  --------
   5      0      10586  494

  HUB version:
    <server url>/debug?manifest
    Product-version: 3.3.0
    Build: jenkins-HubV3.3.x-NightlyRCBuild-7
    Build-time: Mon Aug 08 21:33:46 EDT 2016
    BDS-Hub-UI-Version: 3.3.0  
#>  

# change the following parameters
$BD_HOST="localhost"
$BD_PORT="8080"
$BD_USERNAME="sysadmin"
$BD_PASSWORD="blackduck"
$COOKIE_FILE_NAME="bds-hub-cookie.txt"
$SCHEME="http"

#$DebugPreference = "Continue"

########  DON'T TOUCH THESE PARAMETERS ################
$SCRIPT_DIR=Split-Path -Parent $PSCommandPath
Write-Debug  $SCRIPT_DIR
$CURL_EXE="$SCRIPT_DIR\curl.exe"
#$CURL_EXE="curl"
$COOKIE_FILE_PATH="$SCRIPT_DIR\$COOKIE_FILE_NAME"
Write-Debug $CURL_EXE
$SERVER_URL="http://${BD_HOST}:${BD_PORT}"
######################################################

function Login {
    #get the cookie from the hub
    $OUTPUT=&(${CURL_EXE}) -s -X POST --data "j_username=${BD_USERNAME}&j_password=${BD_PASSWORD}" -i  ${SERVER_URL}/j_spring_security_check -c "$COOKIE_FILE_PATH"
    Write-Debug $OUTPUT.ToString()
}

function Get-RelLink {

    Param ([PSCustomObject]$rep, [string]$rel)

    foreach($link in $rep._meta.links) {
        if($link.rel.Equals($rel)) {
            return $link.href
        }
    }

    Write-Host "Could not find Project/Versions URL: " $rep._meta.links
    Write-Host "Tried looking for rel: " $rel
    return $null
}

## Do we need this??
function Output-ProjectSummary {
    $HUB_PROJECTS=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/v1/risk-profile-projects?limit=100&sortField=name&ascending=true&offset=0&_=1473846139495" | ConvertFrom-Json 
    Write-Debug $HUB_PROJECTS

    # print a table with project data , this is just a sample much more data to display if you want
    $HUB_PROJECTS.items | Select-Object @{Name="id";Expression={ $_.id }},@{Name="Project Name";Expression={ $_.name }}, @{Name="Policy violation";Expression={ $_.policyStatus }}, @{Name="Last scan date";Expression={ $_.lastScanDate }} | Format-Table -AutoSize
}

########################################################################################################################
########################################################################################################################

Login
Output-ProjectSummary

$HUB_PROJECTS_P=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/projects" | ConvertFrom-Json 

foreach( $proj in $HUB_PROJECTS_P.items){
    Write-Host "`n`n################################ PROJECT ################################"

    $project_versions_url = Get-RelLink -rep $proj -rel "versions" 

    if(!$project_versions_url) {
        Write-Host "ERROR: Could not find versions URL for Project: " $proj.name
        continue
    } 

    $proj_versions=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH $project_versions_url | ConvertFrom-Json
    Write-Host "project :" $proj.name
    Write-Host "number of versions :" $proj_versions.totalCount

    foreach( $ver in $proj_versions.items){
        Write-Host "`tversion : " $ver.versionName
        $vulnerable_components_url = Get-RelLink -rep $ver -rel "vulnerable-components"

        if(!$vulnerable_components_url) {
            Write-Host "ERROR: Could not find vulnerable-components URL for Version: " $ver.versionName
            continue
        } 

        $vulnerable_components=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH $vulnerable_components_url | ConvertFrom-Json 

        foreach ($comp in $vulnerable_components.items) {
            Write-Host "`t`tcomponent: " $comp.componentName " " $comp.componentVersionName

            foreach ($vuln in $comp.vulnerabilityWithRemediation){
                Write-Host  "`t`t`t" $vuln.vulnerabilityName
            }
       }
   }
}

