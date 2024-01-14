#######################################################
#INFO TAB - Made by Noel Keller - I4a                 #
#######################################################


ForEach-Object {

$i=0

#Connect to the Azure Active Directory using Credentials
#Connect-AzureAD (-Credential $Cred)
Connect-AzureAD

while ($i -lt 10){

$YesOrNo = Read-Host "Möchtest du den Benutzer deaktivieren(d) oder löschen(l)? (d/l)"

if ($YesOrNo -eq "d") {

    #Den Namen findet man unter Konto -> Benutzeranmeldename
    $Name = Read-Host "Gebe den Benutzeranmeldenamen des austretenden Mitarbeiters ein"

    #Disable User
    Disable-ADAccount -Identity $Name

    #Delete telephoneNumber
    Set-ADUser -Identity $Name -Clear telephoneNumber

    #Get actual Date and Time
    $Date = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
    
    #Delete and Set Description
    Set-ADUser -Identity $Name -Description "Deaktiviert am $Date"

    #Licenses Part
    $UserUPN = $Name+"@saviva.ch"

    $AssignedLicenses = (Get-AzureADUser -ObjectId $UserUPN).AssignedLicenses

    If ($AssignedLicenses.Count -eq 0) {
        Write-Host "Dem Mitarbeiter wurden keine Lizenzen enzogen, da er nicht lizenziert war"
    } else {
        #Remove all licenses of a specific AD-User account
        $userList = Get-AzureADUser -ObjectID $userUPN
        $Skus = $userList | Select -ExpandProperty AssignedLicenses | Select SkuID
            if($userList.Count -ne 0) {
            if($Skus -is [array])
    	    {
            $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
                for ($i=0; $i -lt $Skus.Count; $i++) {
            $licenses.RemoveLicenses +=  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $Skus[$i].SkuId -EQ).SkuID   
    	    }
            Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenses
    	    }   
	    else {
                $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
                $licenses.RemoveLicenses =  (Get-AzureADSubscribedSku | Where-Object -Property SkuID -Value $Skus.SkuId -EQ).SkuID
            Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenses
    	    }
        }
    }
}

elseif ($YesOrNo -eq "l"){
    #Den Namen findet man unter Konto -> Benutzeranmeldename
    $Name = Read-Host "Gebe den Benutzeranmeldenamen des austretenden Mitarbeiters ein"

    $user = Get-ADUser $Name -Properties DirectReports
        if ($user.DirectReports) {
            $Manager = Read-Host "Gebe den Benutzeranmeldenamen des neuen Vorgesetzten (der anstelle des ausrtretenden Mitarbeiter kommt)"

            # Get the distinguished name of the employee who is leaving
            $employee = Get-ADUser -Identity $Name

            # Get the distinguished names of all the employees who report to the employee who is leaving
            $subordinates = Get-ADUser -Filter {Manager -eq $employee.DistinguishedName}

            # Set the new manager for each subordinate
            $newManager = Get-ADUser -Identity $Manager

            foreach ($subordinate in $subordinates) {
                Set-ADUser -Identity $subordinate.DistinguishedName -Manager $newManager.DistinguishedName
            }
                Remove-ADUser -Identity $Name
            } 

            else {
                Remove-ADUser -Identity $Name
            }    
        }

else {
    write-host("Diese eingabe ist nicht korrekt. Bitte starten Sie das Script noch einmal und geben Sie einen gültigen Wert ein!")
}

$Restart = Read-Host "Möchten Sie das Script neustarten (J/N)?"

if ($Restart -eq "J"){
    $i++
}

elseif ($Restart -eq "N") {
    #Disconnect AzureAD to Enter Exchange Modus
    Disconnect-AzureAD 
    break

}

else {
    Disconnect-AzureAD
    break
}

}  

}