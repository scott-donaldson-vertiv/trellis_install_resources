<#Set-StrictMode –Version latest#>
function Resolve-Host {
    <#
    .NOTES
        Copyright 2013 Robert Nees
        Licensed under the Apache License, Version 2.0 (the "License");
        http://sushihangover.blogspot.com
    .SYNOPSIS
        Resolve a host to a set of IP address(es)
    .DESCRIPTION
        This DNS function has the ability to return the first IP address for a host, a number of the addresses (or all), and also supports the 
        "PassThru" parameter to get back an array of IPAddress Class
    .EXAMPLE
        C:PS>Resolve-HostName -ComputerName google.com

        173.194.33.36
    .EXAMPLE
        C:PS>Resolve-HostName google.com -Count -1

        173.194.33.36
        173.194.33.37
        173.194.33.38
        173.194.33.39
        173.194.33.40
        173.194.33.41
        173.194.33.46
        173.194.33.32
        173.194.33.33
        173.194.33.34
        173.194.33.35
    .EXAMPLE 
        C:PS>'google.com' | Resolve-Host -PassThru | Select-Object -ExpandProperty AddressList |ft

          Address AddressFamily ScopeId       IsIPv6Multic IsIPv6LinkLo IsIPv6SiteLo IsIPv6Teredo IsIPv4Mapped IPAddressToS
                                                       ast          cal          cal                    ToIPv6 tring
          ------- ------------- -------       ------------ ------------ ------------ ------------ ------------ ------------
        119653037  InterNetwork                      False        False        False        False        False 173.194.33.7
        136430253  InterNetwork                      False        False        False        False        False 173.194.33.8
        153207469  InterNetwork                      False        False        False        False        False 173.194.33.9
        237093549  InterNetwork                      False        False        False        False        False 173.194.3...
          2212525  InterNetwork                      False        False        False        False        False 173.194.33.0
         18989741  InterNetwork                      False        False        False        False        False 173.194.33.1
         35766957  InterNetwork                      False        False        False        False        False 173.194.33.2
         52544173  InterNetwork                      False        False        False        False        False 173.194.33.3
         69321389  InterNetwork                      False        False        False        False        False 173.194.33.4
         86098605  InterNetwork                      False        False        False        False        False 173.194.33.5
        102875821  InterNetwork                      False        False        False        False        False 173.194.33.6
    .EXAMPLE
        C:PS>Resolve-HostName www.windowsphone.com -PassThru |Select-Object -ExpandProperty AddressList

        Address            : 3870373789
        AddressFamily      : InterNetwork
        ScopeId            :
        IsIPv6Multicast    : False
        IsIPv6LinkLocal    : False
        IsIPv6SiteLocal    : False
        IsIPv6Teredo       : False
        IsIPv4MappedToIPv6 : False
        IPAddressToString  : 157.55.177.230
    .EXAMPLE
        C:PS>@('google.com','www.bing.com') | Resolve-Host -PassThru  | fl

        HostName    : google.com
        Aliases     : {}
        AddressList : {173.194.33.4, 173.194.33.5, 173.194.33.6, 173.194.33.7...}

        HostName    : a134.dsw3.akamai.net
        Aliases     : {}
        AddressList : {96.17.15.115, 96.17.15.139, 23.3.105.35, 23.3.105.17}
    .LINK
        http://sushihangover.blogspot.com
    .LINK
        https://github.com/sushihangover
    #>
    [cmdletbinding(DefaultParameterSetName='Limit',SupportsShouldProcess=$True,ConfirmImpact="Low")]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=1,ValueFromPipelineByPropertyName=$true)][string]$ComputerName,
        [Parameter(ParameterSetName='Limit')][Alias("Count")][Parameter(Mandatory=$false,Position=2,ValueFromPipeLine=$false,ValueFromPipelineByPropertyName=$false)][int]$First = 0,
        [Parameter(ParameterSetName='PassThru')][Parameter(Mandatory=$false,Position=2,ValueFromPipeLine=$false,ValueFromPipelineByPropertyName=$false)][switch]$PassThru
    )
    Process {
        if ($pscmdlet.ShouldProcess("Name lookup on $ComputerName")) {
            $Addresses = [System.Net.DNS]::GetHostEntry($ComputerName)
            if ($PassThru.IsPresent) {
                $return = $Addresses
            } else {
                if ($First -eq 0) {
                    $return = $Addresses.AddressList[0].IPAddressToString
                } elseif ($First -lt 0) {
                    $return = $Addresses.AddressList.IPAddressToString
                } else {
                    $i = 0
                    $return + @()
                    foreach ($Address in $Addresses.AddressList) {
                        # can not use break as this is pipeline'd, so use the old fashion if/else
                        if ($i -lt $Addresses.AddressList.Count) {
                            if ($i -lt $First) {
                                $return =+ $Address.IPAddressToString
                            $i++
                            }
                        }
                    }
                }
            }
            Write-Output $return
        }
    }
} 
