<#
.SYNOPSIS
	Groups and his Memberships query on Active Directory server

.DESCRIPTION
	This is a PowerShell script, which is used to make a group query with his users on an Active Directory server.
	After the query it will export the query to a csv file on the desktop.

.NOTES
	Version:	1.0
	Author:		Jordan Macedo
	Creation Date:	07.12.2020
#>

$ADGroups = @{
    DomainLocal = @{}
    Global = @{}
    Universal = @{}
}

#region Get Members security Groups in AD
Get-ADGroup –Filter * |
ForEach-Object{
    $sAMAccountName = $_.sAMAccountName 
    $name = $_.name
    switch ($_.GroupScope) {
        'DomainLocal' {
            $ADGroups.DomainLocal.$sAMAccountName = Get-ADGroupMember –Identity $sAMAccountName | Select-Object –ExpandProperty name
            
        }
        'Global'{
            $ADGroups.Global.$sAMAccountName = Get-ADGroupMember –Identity $sAMAccountName | Select-Object –ExpandProperty name
           
        }
        'Universal' {
            $ADGroups.Universal.$sAMAccountName = Get-ADGroupMember –Identity $sAMAccountName | Select-Object –ExpandProperty name
            
        }
    }
}
#endregion

#region Get Member Count AD Groups
$ADGroups.Keys |
ForEach-Object{
    $GroupScope = $_

    $ADGroups.$GroupScope.Keys |
    ForEach-Object{
        [PSCustomObject]@{
            Group = $_
            GroupScope = $GroupScope
            Count = @($ADGroups.$GroupScope.$_).Count
        }
    }
}
#endregion

#region Get Security Matrix for Global AD Groups
$htUsers = @{}
$htProps = @{}
$htDis = @{}
$ADGroups.Global.Keys | ForEach-Object {$htProps.$_ = $null}

foreach ($group in $ADGroups.Global.keys){
   foreach ($user in $ADGroups.Global.$($group)){
    
      if (!$htUsers.ContainsKey($user)){
         $htProps.sAMAccountName = $user
         $htUsers.$user = $htProps.Clone()
      }
      ($htUsers.$user).$($group) = 'x'
   }
}


$htUsers.GetEnumerator() +  $htUsers.GetEnumerator()| 
ForEach-Object{
      [PSCustomObject]$($_.Value)
} |
Out-GridView -PassThru | Export-Csv -Path C:\temp\export.csv -Notypeinformation
#endregion
