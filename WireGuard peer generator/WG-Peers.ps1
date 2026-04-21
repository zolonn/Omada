

##############################################
##
##
## OMADA CONTROLLER LOGIN
##
##
##############################################


$global:sServer = "" 
$global:sAccessToken = ""
$global:srefreshToken = ""
$global:sOmadacId = ""
$global:sClientID = "" 
$global:sClientSecret = "" 
$global:oSites = [pscustomobject]@{}
$global:sSiteID = ""
$global:oVPNs = [pscustomobject]@{}
$global:oVPN = [pscustomobject]@{}
$global:sVPNID = ""
$global:oPeers = [pscustomobject]@{}
$global:sPeerID = ""
$global:sNextIP = ""
$global:sExportPath = ""
$global:bSaveEndpoint = $false
$global:Endpoint = ""



function fCtrlGetID
{
param ( $sServer )

    $sURL = "https://$sServer/api/info"
    $oResp = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck #-Headers $aHeaders #-Body $aBody
    if ( $oResp.errorCode -eq 0 ) { $global:sOmadacId = $oResp.result.omadacId }
    return $oResp
}


function fCtrlLogin
{
param ( $sServer, $sOmadacId, $sClientID, $sClientSecret)

    $aHeaders = @{'content-type' = 'application/json' }
    #$aBody = '{"omadacId":"' + $global:sOmadacId + '","client_id":"' + $global:sClientID + '","client_secret":"' + $global:sClientSecret + '"}'
    $aBody = '{"omadacId":"' + $sOmadacId + '","client_id":"' + $sClientID + '","client_secret":"' + $sClientSecret + '"}'
    $sURL = "https://" + $sServer + "/openapi/authorize/token?grant_type=client_credentials"
    $oResp = Invoke-RestMethod -Method 'POST' -Uri $sURL -Headers $aHeaders -Body $aBody -SkipCertificateCheck

    if ( $oResp.errorCode -eq 0 )
        { $global:sAccessToken = $oResp.result.accessToken ;  $global:srefreshToken = $oResp.result.refreshToken}
    return $oResp
}

function fCtrlRefreshToken
{
param ( $sServer, $sOmadacId ) #, $sClientID, $sClientSecret)

    $aHeaders = @{'content-type' = 'application/json' }
    $sURL = "https://$sServer/openapi/authorize/token?client_id=$($global:sClientID)&client_secret=$($global:sClientSecret)&refresh_token=$($global:srefreshToken)&grant_type=refresh_token"
    $oResp = Invoke-RestMethod -Method 'POST' -Uri $sURL -Headers $aHeaders -SkipCertificateCheck #-Body $aBody
    if ( $oResp.errorCode -eq 0 )
        { $global:sAccessToken = $oResp.result.accessToken ; $global:srefreshToken = $oResp.result.refreshToken }
    return $oResp
}


function fCtrlListSites
{
param ( $sServer, $sOmadacId, $sAccessToken)

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v1/$sOmadacId/sites?page=1&pageSize=10"
    $oResp = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    if ( $oResp.errorCode -eq 0 )
        { $global:oSites = $oResp.result.data }
    return $oResp
}

function fCtrlListVPNServers
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID)

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v2/$sOmadacId/sites/$sSiteID/vpn/client-to-site-vpn-servers?page=1&pageSize=10"
    #$sURL = "https://$sServer/openapi/v1/$sOmadacId/sites/$sSiteID/vpn?page=1&pageSize=10"
    $oResp = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    if ( $oResp.errorCode -eq 0 )
        { $global:oVPNs = $oResp.result.data }
    return $oResp
}
function fCtrlListVPNTunnels
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID)

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v2/$sOmadacId/sites/$sSiteID/vpn/site-to-site-vpns?page=1&pageSize=10"
    $oResp = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    if ( $oResp.errorCode -eq 0 )
        { $global:oVPNs = $oResp.result.data }
    return $oResp2
}




function fCtrlListVPNTunnelDetail 
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID, $sVPNID )

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v2/$sOmadacId/sites/$sSiteID/vpn/site-to-site-vpns/$sVPNID"
    $oResp3 = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    return $oResp3
}


function fCtrlUpdateVPNTunnelDetail 
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID, $sWGID, $oRespUpd )

    $aHeadersUpd = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURLUpd = "https://$sServer/openapi/v2/$sOmadacId/sites/$sSiteID/vpn/site-to-site-vpns/$sWGID"
    $oRespUpd.psobject.Properties.Remove("id")
    $oRespUpd.psobject.Properties.Remove("siteVpnType")
    $oRespUpd.psobject.Properties.Remove("publicKey")
    $oRespUpd.psobject.Properties.Remove("featureDescription")
    $aBodyUpd = $oRespUpd | ConvertTo-Json -Depth 99
    $oRespUpd = Invoke-RestMethod -Method 'PATCH' -Uri $sURLUpd -SkipCertificateCheck -Headers $aHeadersUpd -SkipHeaderValidation -Body $aBodyUpd
    return $oRespUpd
}

function fCtrlGetVPNTunnelDetail
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID, $sWGID )

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v2/$sOmadacId/sites/$sSiteID/vpn/site-to-site-vpns/$sWGID"
    $oResp3 = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    return $oResp3
}

function fCtrlGetVPNNewKeys
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID)

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v1/$sOmadacId/sites/$sSiteID/vpn/wireguard-key"
    $oResp3 = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    return $oResp3
}


# get DHCP settings of default (first LAN)
function fCtrlGetDNSServers
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID)

$aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v1/$sOmadacId/sites/$sSiteID/lan-networks?page=1&pageSize=10"
    $oResp = Invoke-RestMethod -Method 'GET' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation #-Body $aBody
    $oResp.result.data[0].dhcpSettingsVO
    return $oResp.result.data[0].dhcpSettingsVO
}


# get DHCP settings of default (first LAN)
function fCtrlSetNewPeer
{
param ( $sServer, $sOmadacId, $sAccessToken, $sSiteID, $sJSON )

    $aHeaders = @{  'content-type' = 'application/json'; 'Authorization' = "AccessToken=$sAccessToken" }
    $sURL = "https://$sServer/openapi/v1/$sOmadacId/sites/$sSiteID/vpn/wireguard-peers"
    $oResp = Invoke-RestMethod -Method 'POST' -Uri $sURL -SkipCertificateCheck -Headers $aHeaders -SkipHeaderValidation -Body $sJSON
    return $oResp
}


function fClearTunnelDetail
{
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerStatusText" -Property "Text" "---"
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerIPText" -Property "Text" "---"
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPortText" -Property "Text" "---"
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerMTUText" -Property "Text" "---"
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPrivKeyText" -Property "Text" "---"
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPubKeyText" -Property "Text" "---"
}




function Event_Process_LoadMainForm
{
    # populate text box with server name
    $global:sServer = $global:oJSONcfg.controller.Host
    $global:sClientID = $global:oJSONcfg.controller.ClientID
    $global:sClientSecret = $global:oJSONcfg.controller.ClientSecret
    $bRet = Set-UI_Property -Form $oMainForm -Control "ServerNameText" -Property "Text" -Value $oJSONcfg.controller.Host

    # get the controller ID
    $oResp = fCtrlGetID $sServer
    # login - when OK paint the background green
    $oResp = fCtrlLogin $sServer $sOmadacId $sClientID $sClientSecret
    if ( $oResp.errorCode -ne 0 )  { Write-Host "Login failed" } # open popup window with error message
    else                           { $bRet = Set-UI_Property -Form $oMainForm -Control "ServerNameText" -Property "BackColor" -Value "Green" }   # !!!! make servename text box green

    # get sites and populate combo box
    $oResp = fCtrlListSites $sServer $sOmadacId $sAccessToken
    if ( $oResp.errorCode -eq -44112)
        {
        Write-Host "Info: Token exprired, refreshing..."
        $oResp = fCtrlRefreshToken $sServer $sOmadacId
        if ( $oResp.errorCode -ne 0 )   { Write-Host "   Error refreshing token: $($oResp.errorCode) - $($oResp.msg)" }
        # Re-reading sites
        $oResp = fCtrlListSites $sServer $sOmadacId $sAccessToken
        if ( $oResp.errorCode -ne 0 )   { Write-Host "Error refreshing $($oResp.errorCode) - $($oResp.msg)" } # !!!! popup window
        }
    $aItems = @() ; foreach ( $oSite in $global:oSites ) { $aItems += "$($oSite.name)" }
    $Ret = Invoke-UI_Method -Form $oMainForm -Control "SiteNameCombo" -Method "Items.AddRange" -Value $aItems
}

function Event_Process_ComboSite
{
    # clear the WG list combo
    $bRet = Invoke-UI_Method -Form $oMainForm -Control "VPNNameCombo" -Method "Items.Clear"
    # clear the peer list combo
    $bRet = Invoke-UI_Method -Form $oMainForm -Control "PeerCombo" -Method "Items.Clear"
    # clear Tunnel details
    fClearTunnelDetail


    # get Site ID
    $sSitename = Get-UI_Property -Form $oMainForm -Control "SiteNameCombo" -Property "SelectedItem"
    $global:sSiteID = $($global:oSites | Where-Object {$_.name -eq $sSitename} | Select-Object -Property "siteId").siteId

    # load WG VPNs
    $oResp = fCtrlListVPNTunnels $sServer $sOmadacId $sAccessToken $sSiteID
    $aItems = @() ; foreach ( $oRow in $global:oVPNs )  { $aItems += "$($oRow.name)" }

    # populate WG list combo
    $Ret = Invoke-UI_Method -Form $oMainForm -Control "VPNNameCombo" -Method "Items.AddRange" -Value $aItems

    #disable New Peer button
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerButton" -Property "Enabled" -Value $false 
    # disable peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "PeerDetailBox" -Property "Visible" -Value $false

    # disable new peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $false
}

function Event_Process_ComboVPN
{
    # clear the peer list combo
    $bRet = Invoke-UI_Method -Form $oMainForm -Control "PeerCombo" -Method "Items.Clear"

    # get VPN ID
    $sVPNname = Get-UI_Property -Form $oMainForm -Control "VPNNameCombo" -Property "SelectedItem"
    $global:sVPNID = $($global:oVPNs | Where-Object {$_.name -eq $sVPNname} | Select-Object -Property "id").id

    # load WG VPN details and peers
    $global:oVPN = $(fCtrlGetVPNTunnelDetail $sServer $sOmadacId $sAccessToken $sSiteID $sVPNID).result
    $global:oPeers = $(fCtrlGetVPNTunnelDetail $sServer $sOmadacId $sAccessToken $sSiteID $sVPNID).result.peers
    
    # populate VPN details
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerStatusText" -Property "Text" -Value $oVPN.status
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerIPText" -Property "Text" -Value $oVPN.tunnelIp
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPortText" -Property "Text" -Value $oVPN.servicePort
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerMTUText" -Property "Text" -Value $oVPN.mtu
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPrivKeyText" -Property "Text" -Value $oVPN.privateKey
    $Ret = Set-UI_Property -Form $oMainForm -Control "ServerPubKeyText" -Property "Text" -Value $oVPN.publicKey

    # populate WG list combo
    $aItems = @() ; foreach ( $oRow in $global:oPeers )  { $aItems += "$($oRow.name)" }
    $Ret = Invoke-UI_Method -Form $oMainForm -Control "PeerCombo" -Method "Items.AddRange" -Value $aItems

    # enable New peer button
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerButton" -Property "Enabled" -Value $true
    # disable peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "PeerDetailBox" -Property "Visible" -Value $false
    # disable new peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $false
}

function Event_Process_PeersList
{
    # was combo cleared? if yes, stop processing
    if ( $(Get-UI_Property -Form $oMainForm -Control "PeerCombo" -Property "SelectedIndex") -eq -1) { return }
    # get Peer ID
    $sPeerName = Get-UI_Property -Form $oMainForm -Control "PeerCombo" -Property "SelectedItem"
    $global:sPeerID = $($global:oPeers | Where-Object {$_.name -eq $sPeerName} )# | Select-Object -Property "id").siteId

    # enable peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "PeerDetailBox" -Property "Visible" -Value $true
    # disable new peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $false

    # look for Priv Key  and DNS in CFG file
    $bRet = Set-UI_Property -Form $oMainForm -Control "ExportPeerButton" -Property "Enabled" -Value $true
    $sPrivKey = $oJSONcfg.peers.$sPeerName.PrivateKey ; 
    if ( $null -eq $sPrivKey) { $sPrivKey = "<not maintained by Peer Creator>" ; $bRet = Set-UI_Property -Form $oMainForm -Control "ExportPeerButton" -Property "Enabled" -Value $false }
    $sDNS = $oJSONcfg.peers.$sPeerName.DNS ; 
    if ( $null -eq $sDNS) { $sDNS = "<not maintained by Peer Creator>" ; $bRet = Set-UI_Property -Form $oMainForm -Control "ExportPeerButton" -Property "Enabled" -Value $false }

    # populate VPN details
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerStatusText" -Property "Text" -Value $($global:sPeerID).status
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerIPText" -Property "Text" -Value $($global:sPeerID).remoteSubnet[0]
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerPrivKeyText" -Property "Text" -Value $sPrivKey
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerPubKeyText" -Property "Text" -Value $($global:sPeerID).serverPublicKey
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerSubnetText" -Property "Text" -Value "0.0.0.0/0"
    $Ret = Set-UI_Property -Form $oMainForm -Control "PeerDNSText" -Property "Text" -Value $sDNS

    $aSubnets = $global:sPeerID.remoteSubnet
}


function Event_Add_NewPeer
{
    # disable peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "PeerDetailBox" -Property "Visible" -Value $false
    # enable new peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $true
    #enable save button
    $bRet = Set-UI_Property -Form $oMainForm -Control "SaveNewPeerButton" -Property "Enabled" -Value $true
    # clear peer name
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerNameText" -Property "Text" -Value ""
   # clear peer name in combo box
    $bRet = Set-UI_Property -Form $oMainForm -Control "PeerCombo" -Property "SelectedIndex" -Value -1
    #$Ret = Invoke-UI_Method -Form $oMainForm -Control "PeerCombo" -Method "ResetText" 

    # get Endpoint from config file
    $sSitename = Get-UI_Property -Form $oMainForm -Control "SiteNameCombo" -Property "SelectedItem"
    $sEndpoint = $oJSONcfg.tunnelAdresses.$sSitename
    if ( $null -eq $sEndpoint ) { $bRet = Set-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text" -Value "<Enter public FQDN of the tunnel>" ; $global:bSaveEndpoint = $true }
    else { $bRet = Set-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text" -Value $sEndpoint ; $global:bSaveEndpoint = $false }
    # serviceport cannot be changed - must be the same as at VPN server
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewEndPointPortText" -Property "Text" -Value $global:oVPN.servicePort
    #get new keys for peer and populate
    $oResp = fCtrlGetVPNNewKeys $sServer $sOmadacId $sAccessToken $sSiteID
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerPrivKeyText" -Property "Text" -Value $oResp.result.privateKey
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerPubKeyText" -Property "Text" -Value $oResp.result.publicKey

    # calculate the next IP address
    # - if there is more than one remote subnet, this isn't client VPN....

    if ( $($global:oPeers[0].remoteSubnet).Count -gt 1 )
        {
        fDisplayMessageBox "New Peer" "This VPN has more than one remote network ranges.`r`nIs probably site2site VPN.`r`n`r`nAdding new peer is not allowed."
        $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $false
        return
        }
    

    # get ranges, sort and get the latest (highest) one 
    $aRanges = @() ; foreach ( $oRow in $global:oPeers )  { $aRanges += $($oRow.remoteSubnet[0]).ToString() }
    if ( $aRanges.Count -eq 0 )
        { #no peers yet, get the server IP and start with 10....
        $sIP = $global:oVPN.tunnelIp
        $sIP = $sIP.SubString( 0,$sIP.LastIndexOf(".")+1)
        $sIP += "10/32"
        }
    else
        { # some peers exists
        if ( $aRanges.Count -eq 1 ) { $global:sNextIP = $aRanges[0]    }
        else                        { $aRanges = $aRanges | Sort-Object ; $global:sNextIP = $aRanges[$aRanges.Length-1]    }
        
        # split network, IP and mask (assuming only the 4th octet is relevant)
        $sNet = $($global:sNextIP).SubString( 0,$($global:sNextIP).LastIndexOf(".")+1)
        $iIPlen = $($global:sNextIP).IndexOf("/") - $($global:sNextIP).LastIndexOf(".") - 1
        $sIP = $($global:sNextIP).SubString( $($global:sNextIP).LastIndexOf(".")+1,$iIPlen)
        $sMask = $($global:sNextIP).SubString( $($global:sNextIP).LastIndexOf("/"))
        # add 1 to IP
        $sIP = $([int]$sIP + 1).ToString()
        # construct the range back
        $sIP = $sNet + $sIP + $sMask
        }
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerIPText" -Property "Text" -Value $sIP
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerRangeText" -Property "Text" -Value "0.0.0.0/0"
    # - get DNS servers
    $oResp =  fCtrlGetDNSServers $sServer $sOmadacId $sAccessToken $sSiteID
    if ( $($oResp[0].sndDns) -eq "") { $sDNS = "$($oResp[0].priDns)" } else { $sDNS = "$($oResp[0].priDns), $($oResp[0].sndDns)" }
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerDNSText" -Property "Text" -Value $sDNS


}

function Event_Save_NewPeer
{

    # check the mandatory fields
    if ( $(Get-UI_Property -Form $oMainForm -Control "NewPeerNameText" -Property "Text") -eq "" )
        {
        fDisplayMessageBox "New Peer Name" "New Peer Name cannot be blank!"
        return
        }
    if ( $(Get-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text") -eq "" )
        {
        fDisplayMessageBox "New Peer EndPoint" "New Peer EndPoint cannot be blank!"
        return
        }
    if ( $(Get-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text") -like "<*>" )
        {
        fDisplayMessageBox "New Peer EndPoint" "New Peer EndPoint cannot be hint text!"
        return
        }


    # if needed add site FQDN
    if ( $global:bSaveEndpoint -eq $true )
        {
        $sSitename = Get-UI_Property -Form $oMainForm -Control "SiteNameCombo" -Property "SelectedItem"
        $sEndpoint = Get-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text"
        $oJSONcfg.tunnelAdresses | Add-Member -NotePropertyName $sSitename -NotePropertyValue $sEndpoint
        #$global:oJSONcfg.tunnelAdresses += $aValue
        $i++
        }

    # add private and public key
    $sPeerName = Get-UI_Property -Form $oMainForm -Control "NewPeerNameText" -Property "Text"
    $sPrivKey = Get-UI_Property -Form $oMainForm -Control "NewPeerPrivKeyText" -Property "Text"
    $sPubKey = Get-UI_Property -Form $oMainForm -Control "NewPeerPubKeyText" -Property "Text"
    $sDNS = Get-UI_Property -Form $oMainForm -Control "NewPeerDNSText" -Property "Text"
    $oJSONcfg.peers | Add-Member -NotePropertyName $sPeerName -NotePropertyValue @{PrivateKey=$sPrivKey;PublicKey=$sPubKey;DNS=$sDNS}
    # save and reload JSON config file
    $oJSONOut = $global:oJSONcfg | ConvertTo-Json -Depth 99 | Out-File -FilePath "$sScriptPath.cfg.json"
    $global:oJSONcfg = Get-Content -Raw -Path "$sScriptPath.cfg.json" | ConvertFrom-Json
    $oJSONOut = $null


    # export config file for peer
    "[Interface]" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf"
    "PrivateKey = $sPrivKey" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "Address = $(Get-UI_Property -Form $oMainForm -Control "NewPeerIPText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "DNS = $(Get-UI_Property -Form $oMainForm -Control "NewPeerDNSText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "[Peer]" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "PublicKey = $sPubKey" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "AllowedIPs = 0.0.0.0/0" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    $sEndpoint = "$(Get-UI_Property -Form $oMainForm -Control "NewEndPointText" -Property "Text"):$(Get-UI_Property -Form $oMainForm -Control "NewEndPointPortText" -Property "Text")"
    "Endpoint = $sEndpoint" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append

    # create new entry on Controller
    # - construct JSON for POST
    $sJSONnewPeer = '{"name": "' + $sPeerName + '", "status": true, "interfaceId": "' + $global:oVPN.id + '", '
    $sJSONnewPeer += '"publicKey": "' + $sPubKey + '", '#"endPoint": "", "endPointPort": 0, '
    $sJSONnewPeer += '"allowAddress": ["' + $(Get-UI_Property -Form $oMainForm -Control "NewPeerIPText" -Property "Text") + '"], "keepAlive": 25, "comment":"Created by WireGuard Peer Creator" }'
    # - create new entry
    $oResp = fCtrlSetNewPeer $sServer $sOmadacId $sAccessToken $sSiteID $sJSONnewPeer

    # disable new peer detail box
    $bRet = Set-UI_Property -Form $oMainForm -Control "NewPeerBox" -Property "Visible" -Value $false

    Event_Process_ComboVPN
}

function Event_Export_Peer 
{
    # export config file for peer
    $sPeerName = Get-UI_Property -Form $oMainForm -Control "PeerCombo" -Property "SelectedItem"
    "[Interface]" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf"
    "PrivateKey = $(Get-UI_Property -Form $oMainForm -Control "PeerPrivKeyText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "Address = $(Get-UI_Property -Form $oMainForm -Control "PeerIPText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "DNS = $(Get-UI_Property -Form $oMainForm -Control "PeerDNSText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "[Peer]" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "PublicKey = $(Get-UI_Property -Form $oMainForm -Control "PeerPubKeyText" -Property "Text")" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    "AllowedIPs = 0.0.0.0/0" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
    $sSitename = Get-UI_Property -Form $oMainForm -Control "SiteNameCombo" -Property "SelectedItem"
    $sEndpoint = $sEndpoint = "$($oJSONcfg.tunnelAdresses.$sSitename):$($oVPN.servicePort)"
    "Endpoint = $sEndpoint" | Out-File -FilePath "$($global:sExportPath)\$sPeerName.conf" -Append
}

function fDisplayMessageBox 
{
param ( $sCaption, $sText )
    $oRes = [System.Windows.Forms.MessageBox]::Show($sText, $sCaption, 1) ; $oRes = $null
}

function About_Msg 
{ fDisplayMessageBox "About Peer Creator" "Version 0.1.0`r`n`n(c)2026 n-cs.eu" }




###############################################################################################
###############################################################################################
###
### M A I N
###
### The main loads the UI structure from JSON file and doesn't contain any actions - except .ShowDialog().
### As this script is UI-based, the rules of event-driven programming are in place,
### this means, all real actions are driven by UI-object event handlers
###
###############################################################################################
###############################################################################################


    # construct path bases based on directory from where the script is located
    # get the current path... 
    $sScriptPath = $MyInvocation.MyCommand.Definition
    $sScriptPath = $sScriptPath.Substring(0,$sScriptPath.LastIndexOf("."))
    $sLibPath = Split-Path -Parent $sScriptPath
#    $sLibPath = "C:\Scripts\UI_Lib"

    # ...load the library...
    . "$sLibPath\UI_Lib-v3.ps1"

    # ...and read the Form and Logic definitions
    $oJSONforms = Get-Content -Raw -Path "$sScriptPath.forms.json" | ConvertFrom-Json
    $oJSONcfg = Get-Content -Raw -Path "$sScriptPath.cfg.json" | ConvertFrom-Json
    $global:sExportPath = $ExecutionContext.InvokeCommand.ExpandString("$($oJSONcfg.exportPath)")

    # Build the Form Objects from the JSON definition file
    $oForms = UI_Build_Forms -Definition $oJSONforms
    
    # set the first form as the current one
    $oMainForm = $oForms.$($oJSONforms.Forms[0].Name)
    $oCurrentForm = $oMainForm

    # start the app - Display the Form
    $RetVal = $oMainForm.ShowDialog()

    $i++ ### => debug - breakpoint

