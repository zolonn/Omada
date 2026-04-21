

#############################################################################################
#############################################################################################
###
### U I   F O R M   L I B R A R Y
###
### for list of controls to build UI see following reference:
### https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.form?view=windowsdesktop-8.0
###
#############################################################################################
#############################################################################################

$ErrorActionPreference = "Stop"
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing




#############################################################################################
#############################################################################################
###
### M A I N   F U N C T I O N S
###
#############################################################################################
#############################################################################################

#--------------------------------------------------------------------------------------------------------------
# adds UI Control Object to the Controls collection of Control defined by Form name and Control name
# Note: not intended to be used alone
#--------------------------------------------------------------------------------------------------------------
function Add-UI_Control
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Form")] $oForm, 
        [Parameter(<#mandatory=$true#>)] [alias("Control")] $sCtrlName, 
        [Parameter(<#mandatory=$true#>)] [alias("Object")] $oObject )

# please note:
# standard controls (like GroupBox) have ther child items in Control collection.
# control like MenuStrip have their child in Items collection
# and finally (to be little bit more confused :-) ) menu elements itself have their chindren in DropDownItems collection

    
    if ( $sCtrlName -eq "" ) { $oObj = $oForm } else { $oObj = Get-UI_Control -Form $oForm -Control $sCtrlName }
    if ( $null -eq $oObj )  { return $false }
    else                    {
                            $oObjType = $oObj.Gettype() 
                            $iii++
                            switch ( $oObjType.FullName )
                                {
                                "System.Windows.Forms.MenuStrip" 
                                    { $oObj.Items.Add($oObject) }
                                "System.Windows.Forms.StatusStrip" 
                                    { $oObj.Items.Add($oObject) }

                                "System.Windows.Forms.ToolStripMenuItem"
                                    { $oObj.DropDownItems.Add($oObject) }

                                default { $oObj.Controls.Add($oObject) }
                                }
                            
                            return $true }
}

#--------------------------------------------------------------------------------------------------------------
# returns UI Control Object defined by Form name and Control name
# Note: not intended to be used alone
#--------------------------------------------------------------------------------------------------------------
function Get-UI_Control
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Form")] $oForm, 
        [Parameter(<#mandatory=$true#>)] [alias("Control")] $sCtrlName )

# see notes at Add-UI_Control function

    # look in classic controls
    $oObj = $oForm

    $oObjType = $oForm.Gettype() 
    $iii++

    switch ( $oObjType.FullName )
        {
        "System.Windows.Forms.ToolStripMenuItem"
            { # just look at DropDownItems collections
            foreach ( $oSObj in $oObj.DropDownItems ) 
                {
                if ( $oSObj.Name -eq $sCtrlName ) { return $oSObj } 
                if ( $oSObj.DropDownItems.Count -gt 0 )
                    {
                    foreach ( $oDropItem in $oSObj.DropDownItems ) 
                        {
                        if ( $oDropItem.Name -eq $sCtrlName ) { return $oDropItem } 
                        $oRet = Get-UI_Control -Form $oDropItem -Control $sCtrlName ; 
                        if ( $null -ne $oRet ) { return $oRet }        
                        }
                    }
                }
            
            $iiii++
            }

        default
            { 
            # looking for standard control ot top level menu titem sofar
            foreach ( $oSObj in $oObj.Controls ) 
                {
                if ( $oSObj.Name -eq $sCtrlName ) { return $oSObj }
                if ( $oSObj.Controls.Count -gt 0 ) 
                    { 
                    $oRet = Get-UI_Control -Form $oSObj -Control $sCtrlName ; 
                    if ( $null -ne $oRet ) { return $oRet } 
                    }
                }

            #try to look into Items collection
            foreach ( $oSObj in $oObj.Controls ) 
                {
                if ( $oSObj.Items.Count -gt 0 ) 
                    { 
                    foreach ($oItem in $oSObj.Items) 
                        { 
                        if ( $oItem.Name -eq $sCtrlName ) { return $oItem } 
                        if ( $oItem.DropDownItems.Count -gt 0 )
                            {
                            foreach ( $oDropItem in $oItem.DropDownItems ) 
                                {
                                if ( $oDropItem.Name -eq $sCtrlName ) { return $oDropItem } 
                                $oRet = Get-UI_Control -Form $oDropItem -Control $sCtrlName ; 
                                if ( $null -ne $oRet ) { return $oRet }        
                                }
                            }
                        }

                    }
                if ( $oSObj.Controls.Count -gt 0 ) 
                    { 
                    $oRet = Get-UI_Control -Form $oSObj -Control $sCtrlName ; 
                    if ( $null -ne $oRet ) { return $oRet } 
                    }
                }
            }
            

        }
        
    return $null
}

#--------------------------------------------------------------------------------------------------------------
# gets Property value
#--------------------------------------------------------------------------------------------------------------
function Get-UI_Property
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Form")] $oForm, 
        [Parameter(<#mandatory=$true#>)] [alias("Control")] $sCtrlName, 
        [Parameter(<#mandatory=$true#>)] [alias("Property")] $sPropName )

    $oObj = Get-UI_Control -Form $oForm -Control $sCtrlName
    if ( $null -eq $oObj )  { return $false }
    else                    { return $oObj.$($sPropName) }
}

#--------------------------------------------------------------------------------------------------------------
# sets Property value
#--------------------------------------------------------------------------------------------------------------
function Set-UI_Property
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Form")] $oForm, 
        [Parameter(<#mandatory=$true#>)] [alias("Control")] $sCtrlName, 
        [Parameter(<#mandatory=$true#>)] [alias("Property")] $sPropName,
        [Parameter(<#mandatory=$true#>)] [alias("Value")] $sPropVal )

    $oObj = Get-UI_Control -Form $oForm -Control $sCtrlName
    if ( $null -eq $oObj )  { return $false }
    else                    { $oObj.$($sPropName) = $sPropVal ; return $true }
}

#--------------------------------------------------------------------------------------------------------------
# adds UI Control Object to the Controls collection of Control defined by Form name and Control name
# Note: not intended to be used alone
#--------------------------------------------------------------------------------------------------------------
function Invoke-UI_Method
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Form")] $oForm, 
        [Parameter(<#mandatory=$true#>)] [alias("Control")] $sCtrlName, 
        [Parameter(<#mandatory=$true#>)] [alias("Method")] $sMethod,
        [alias("Value")] $oParams )
    
    if ( $sObjName -eq "" ) { $oObj = $oForm } else { $oObj = Get-UI_Control -Form $oForm -Control $sCtrlName }
    if ( $null -eq $oObj )  { return $false }
    else                    {
                            if ( $null -eq $oParams )
                                {
                                if ( $sMethod.IndexOf(".") -ne -1 ) { $sMethods = $sMethod.Split(".") ; $oObj.$($sMethods[0]).$($sMethods[1])() }
                                else                                { $oObj.$($sMethod)() }
                                }
                            else 
                                {
                                if ( $sMethod.IndexOf(".") -ne -1 ) { $sMethods = $sMethod.Split(".") ; $oObj.$($sMethods[0]).$($sMethods[1])($oParams) }
                                else                                { $oObj.$sMethod($oParams) }
                                }
                            return $true 
                            }
}

#--------------------------------------------------------------------------------------------------------------
# populates one Form with Controls from JSON
#--------------------------------------------------------------------------------------------------------------
function Add-UI_Forms_Controls
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Definition")] $oJSON,
        [Parameter(<#mandatory=$true#>)] [alias("Form")] $oMainForm,
        [Parameter(<#mandatory=$true#>)] [alias("Controls")] $oForm,
        [Parameter(<#mandatory=$true#>)] [alias("ControlName")] $sControlName )

    foreach ($oCtrl in $oForm.Controls)
        {
        
        $oNCtrlDef = $oJSON.Controls.$($oCtrl.Name)
        if ( $null -eq $oNCtrlDef ) { Write-Host -ForegroundColor Red "DEFINITION ERROR: Control ""$($oCtrl.Name)"" has no Properties definition" ; continue }
        try { $oNCtrl = New-Object $($oNCtrlDef.Type) } catch { Write-Host -ForegroundColor Red "DEFINITION ERROR: Control ""$($oCtrl.Name)"" is of unknown type: ""$($oNCtrlDef.Type)""" ; continue }
        $oNCtrl.Name = $oCtrl.Name # create control
        # some controls don't have size and/or position properties (like menu strip)
        if ( $null -ne $oNCtrlDef.Pos )  { $oNCtrl.Location = New-Object System.Drawing.Size($oNCtrlDef.Pos[0],$oNCtrlDef.Pos[1]) } # set location
        if ( $null -ne $oNCtrlDef.Size ) { $oNCtrl.Size = New-Object System.Drawing.Size($oNCtrlDef.Size[0],$oNCtrlDef.Size[1]) }   # set size
            
        # set other properties
        foreach ( $oCtrlProp in $($oNCtrlDef.Properties).PsObject.Properties )
            {
            switch ( $oCtrlProp.Type )
                {
                "Items"     { $oNCtrl.$($oCtrlProp.Name).Clear() ; $oNCtrl.ResetText() ; $oNCtrl.$($oCtrlProp.Name).AddRange([System.Windows.Forms.ToolStripItemCollection]$oCtrlProp.Value) } 
                default     {
                            try     { $oNCtrl.$($oCtrlProp.Name) = $oCtrlProp.Value }
                            catch   { Write-Host -ForegroundColor Red "DEFINITION ERROR: Control ""$($oCtrl.Name)"" of type ""$($oNCtrlDef.Type)"" doesn't have Property of ""$($oCtrlProp.Name)""" } 
                            }
                }
            }
        # handles array of action hadlers
        if ( $null -ne $oNCtrlDef.ActionHandlers ) 
            { 
            foreach ( $oHandler in $oNCtrlDef.ActionHandlers ) 
                { 
                try     { $oNCtrl.$($oHandler.ActionType)( (Get-Command $($oHandler.Action) -ErrorAction Stop).ScriptBlock ) } 
                catch   { Write-Host -ForegroundColor Red "DEFINITION ERROR: Action handler function ""$($oHandler.Action)"" of Control ""$($oCtrl.Name)"" could not be found!" }
                }
            }
        # if debug is defined, load grid background image
        try     { if ($oNCtrlDef.Debug -eq "true") { $oNCtrl.BackgroundImage = $pDebugImg } }
        catch   { Write-Host -ForegroundColor Red "DEFINITION ERROR: Control ""$($oCtrl.Name)"" doesn't support backgroud images!" }

        # add the control to the Form Object
        $bRet = Add-UI_Control -Form $oMainForm -Control $sControlName -Object $oNCtrl ; $oNCtrl = $null
        $iii++
        #$bRet = Add-UI_Control -Form $oMainForm -Control $oCtrl.Name -Object $oNCtrl ; $oNCtrl = $null
        # if there are sub-control elements, add them recursively
        if ( $oCtrl.Controls.Count -gt 0 ) 
            { Add-UI_Forms_Controls -Definition $oJSON -Form $oMainForm -Controls $oCtrl -ControlName $oCtrl.Name }
        }
}

#--------------------------------------------------------------------------------------------------------------
# builds complete forms from JSON
#--------------------------------------------------------------------------------------------------------------
function UI_Build_Forms
{
param ( [Parameter(<#mandatory=$true#>)] [alias("Definition")] $opJSON )

    $opForms = New-Object psobject
    foreach ($oForm in $opJSON.Forms)
        {
        $oFormDef = $opJSON.Controls.$($oForm.Name)                                                         # load Forms definition
        $oNForm = New-Object -TypeName $($oFormDef.Type)                                                    # Create Form object
        $oNForm.Size = New-Object System.Drawing.Size($oFormDef.Size[0],$oFormDef.Size[1])                  # set size
        foreach ( $oFormProp in $($oFormDef.Properties).PsObject.Properties )                               # set other properties
            { $oNForm.$($oFormProp.Name) = $oFormProp.Value }
        # handles array of action hadlers
        if ( $null -ne $oFormDef.ActionHandlers ) 
            { 
            foreach ( $oHandler in $oFormDef.ActionHandlers ) 
                { 
                try     { $oNForm.$($oHandler.ActionType)( (Get-Command $($oHandler.Action) -ErrorAction Stop).ScriptBlock ) } 
                catch   { Write-Host -ForegroundColor Red "DEFINITION ERROR: Action handler function ""$($oHandler.Action)"" of Control ""$($oFormDef.Name)"" could not be found!" }
                }
            }

        if ($oFormDef.Debug -eq "true")                                                                     # if debug is defined, load grid background image
            { $oNForm.BackgroundImage = $pDebugImg }
        $opForms | Add-Member -MemberType NoteProperty –Name $oForm.Name –Value $oNForm  ; $oNForm = $null  # add the Form object to collection
        $bRet = Add-UI_Forms_Controls -Definition $opJSON -Form $opForms.$($oForm.Name) -Controls $oForm "" # add Controls to Form
        }
    return $opForms
}

#-------------------------------------------------
function Close_CurrentForm
{
    $oMainForm.Close()
}



#############################################################################################
#############################################################################################
###
### M A I N
###
#############################################################################################
#############################################################################################



$pDebugImg = [convert]::FromBase64String( "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAYAAABw4pVUAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAARkSURBVHhe7ddhaiQ5EERh3/+KvoUvsEs1IzPkfsXGv1CJCtDIZD8eNDEp6K9/gnx/f88R0+K+vr7miEl9Le76Hv/5Jj8/P3NE4U6cChGX+locC1EkVFpcmtTX4liImpNwJ+64DVkf3t1LOOfzbnGrkDmfd+prccdsiCIu9bU4FqJIqLQ4PVlK6mtxLETNSbgTp0LEpb4Wx0IUCZUWlyb1tbhPIRf89HN9kTl74jlmQ/RkKamvxbEQvW0S7sQp4lJfi2MhioRKi3s3ZDNOhYhLfS3ut5D14d29hHM+7xa3MufzTn0t7t2QzTgWokiotDgVoqS+FsdC1JyEO3GKuNTX4liIIqHS4o7akAt++rm+yJw98RyzIWlSX4tjIXrbJNyJ05MlLvW1OBaiSKi0OBWipL4Wx0LUnIQ7cYq41NfijvmlvjZkzued+lrcMRuiJ0tc6mtxLESRUGlxaVJfi2Mhak7Cnbh3Q27S4lSIkvpa3KeQC376uTJnTzzvhtykxbEQvW0S7sSpEHGpr8WxEEVCpcWlSX0tjoWoOQl34o7bkPXh3b2Ecz7vFrcKmfN5p74Wd8yGKOJSX4tjIYqESovTk6WkvhbHQtSchDtxKkRc6mtxLESRUGlxaVJfizvml/r1RebsieeYDdGTpaS+FsdC9LZJuBOniEt9LY6FKBIqLe7dkM04FSIu9bW430LWh3f3Es75vFvcypzPO/W1uHdDNuNYiCKh0uJUiJL6WhwLUXMS7sQp4lJfi2MhioRKiztqQ/788/fg/bv59+ev/0nacItLk/paHAvR2ybhTtz6H/Z3xKW+FsdCFAmVFqdClNTX4liImpNwJ04Rl/pa3G8h68O7ewnnfN4tbm3InM879bW4YzZET5a41NfiWIgiodLi0qS+FsdC1JyEO3HvhtykxakQJfW1uE8hF/z0c2XOnnjeDblJi2Mhetsk3IlTIeJSX4tjIYqESotLk/paHAtRcxLuxB23IevDu3sJ53zeLW4VMufzTn0t7pgNUcSlvhbHQhQJlRanJ0tJfS2Ohag5CXfiVIi41NfiWIgiodLi0qS+FnfML/Xri8zZE88xG6InS0l9LY6F6G2TcCdOEZf6WhwLUSRUWty7IZtxKkRc6mtxv4WsD+/uJZzzebe4lTmfd+prce+GbMaxEEVCpcWpECX1tTgWouYk3IlTxKW+FsdCFAmVFnfUhlzw08/1RebsieeYDUmT+locC9HbJuFOnJ4scamvxbEQRUKlxakQJfW1OBai5iTciVPEpb4Wd8wv9bUhcz7v1NfijtkQPVniUl+LYyGKhEqLS5P6WhwLUXMS7sS9G3KTFqdClNTX4j6FXPDTz5U5e+J5N+QmLY6F6G2TcCdOhYhLfS2OhSgSKi0uTeprcSxEzUm4E3fchqwP7+4lnPN5t7hVyJzPO/W1uGM2RBGX+locC1EkVFqcniwl9bU4FqLmJNyJUyHiUl+LYyGKhEqLS5P6WtynkD//vGeT8y8Jh93rqN/juQAAAABJRU5ErkJggg==")
$pDebugImg =  [System.Drawing.Image]$pDebugImg
