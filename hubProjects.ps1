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
$BD_HOST="192.168.2.16"
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
$COOKIE_FILE_PATH="$SCRIPT_DIR\$COOKIE_FILE_NAME"
Write-Debug $CURL_EXE
$SERVER_URL="http://${BD_HOST}:${BD_PORT}"
######################################################


#get the cookie from the hub
$OUTPUT=&(${CURL_EXE}) -s -X POST --data "j_username=${BD_USERNAME}&j_password=${BD_PASSWORD}" -i  ${SERVER_URL}/j_spring_security_check -c "$COOKIE_FILE_PATH"
Write-Debug $OUTPUT.ToString()

$HUB_PROJECTS=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/v1/risk-profile-projects?limit=100&sortField=name&ascending=true&offset=0&_=1473846139495" | ConvertFrom-Json 
Write-Debug $HUB_PROJECTS


# print a table with project data , this is just a sample much more data to display if you want
$HUB_PROJECTS.items | Select-Object @{Name="id";Expression={ $_.id }},@{Name="Project Name";Expression={ $_.name }}, @{Name="Policy violation";Expression={ $_.policyStatus }}, @{Name="Last scan date";Expression={ $_.lastScanDate }} | Format-Table -AutoSize


foreach( $proj in $HUB_PROJECTS.items){
   Write-Host "`n`n################################ PROJECT ################################"
   $id=$proj.id
   $proj_versions=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/v1/composite/projects/${id}/releases?limit=100&sortField=bomCounts&ascending=false&offset=0&additionalInfoOptions=BomCount&additionalInfoOptions=VulnerabilitiesCount&additionalInfoOptions=ScanDate&additionalInfoOptions=LastBomUpdateDate&additionalInfoOptions=RiskProfile" | ConvertFrom-Json
   Write-Host "project :" $proj.name
   Write-Host "number of versions :" $proj_versions.totalCount
   foreach( $ver in $proj_versions.items){
        Write-Host "`tversion : " $ver.release.version
        Write-Debug  $ver.release.id
        $ver_id=$ver.release.id        
        $vulnerable_components=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/v1/releases/$ver_id/vulnerability-bom?limit=100&sortField=project.name&ascending=true&offset=0&aggregationEntityType=RL&inUseOnly=true&filter=remediationType%3ANEEDS_REVIEW&filter=remediationType%3AREMEDIATION_REQUIRED&filter=remediationType%3ANEW" | ConvertFrom-Json 
        #Write-Host "    " $vulnerable_components
        foreach ( $comp in $vulnerable_components.items){
           Write-Host "`t`tcomponent: " $comp.project.name " " $comp.release.version
           $oss_comp_id=$comp.project.id
           $oss_comp_release_id=$comp.release.id
           $channelRelease_id=$comp.channelRelease.id
           Write-Debug "${SERVER_URL}/api/v1/releases/$id/RL/$ver_id/channels/$channelRelease_id/vulnerabilities?limit=100&sortField=baseScore&offset=0"
           $oss_comp_vulnerabilities=&(${CURL_EXE}) -s -X GET --header "Accept: application/json" -b $COOKIE_FILE_PATH "${SERVER_URL}/api/v1/releases/$ver_id/RL/$oss_comp_release_id/channels/$channelRelease_id/vulnerabilities?limit=100&sortField=baseScore&offset=0" | ConvertFrom-Json 
           Write-Debug $oss_comp_vulnerabilities
           foreach ( $vuln in $oss_comp_vulnerabilities.items){
              Write-Host  "`t`t`t" $vuln.id
           }
        }
        
   }
}

