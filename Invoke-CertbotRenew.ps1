Param()

Begin {
  $CertBot = (Get-Command -Name "certbot" -ErrorAction SilentlyContinue);
  if ($Null -eq $CertBot) {
    $CertBot = "/usr/bin/certbot";
  } Else {
    $CertBot = $CertBot.Source;
  }
  $ACME = (Get-Command -Name "acme.sh" -ErrorAction SilentlyContinue);
  if ($Null -eq $ACME) {
    $ACME = "/root/.acme.sh/acme.sh";
  } Else {
    $ACME = $ACME.Source;
  }

  $Service = (Get-Command -Name "service" -ErrorAction SilentlyContinue);
  if ($Null -eq $Service) {
    Throw "Could not find command by the name of `"service`".";
  } Else {
    $Service = $Service.Source;
  }

  $ExitCode = 1;

  $Domain = (Get-Content -LiteralPath "/etc/hostname")
  $CloudFlare = $True
  $CloudFlareApi = "$($HOME)/.config/certbot/cloudflare.ini"
  $CloudFlareSettings = "$($HOME)/.config/certbot/cloudflare_settings.cfg"
  $CloudFlareZone = "00000000000000000000000000000000"
  $CloudFlareDefaultSsl = "strict"
  $CloudFlareRenewSsl = "flexible"
  $CloudFlareEmail = "user@example.com"

  $CF_Token = $((Get-Content -LiteralPath $CloudFlareApi | Select-String "dns_cloudflare_api_token") -Replace "dns_cloudflare_api_token = ", "")
  $env:CF_Token = $CF_Token;
  $env:CF_Account_ID = $CloudFlareEmail;
  $env:CF_Zone_ID = $CloudFlareZone;
}
Process
{
  function Test-SslExpire {
    Param()
    $local:cloudflareKey = ((Get-Content -LiteralPath $CloudFlareSettings | Select-String "dns_cloudflare_api_key") -Replace "dns_cloudflare_api_key = ", "");
    $local:data = (Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4/zones/$($CloudFlareZone)/ssl/certificate_packs" -Headers @{
      "Content-Type" = "application/json";
      "X-Auth-Email" = "$($CloudFlareEmail)";
      "X-Auth-Key" = "$($local:cloudflareKey)";
    } -ErrorAction Continue);
    If (-not $local:data.success) {
      $local:error = "Failed to load data from CloudFlare Rest API.`n"
      $local:error += "errors:   $($local:data.errors.code) - $($local:data.errors.message)`n"
      $local:error += "messages: $($local:data.messages.code) - $($local:data.messages.message)"
      Throw $local:error
    }
    $local:expiresOn = ($local:data.result.Where({ $_.hosts -contains "example.com" }).certificates.Where({ $_.hosts -contains "example.com" }).expires_on);
    $local:dateNow = ([System.DateTime]::Now);
    Write-Output -NoEnumerate -InputObject ($local:expiresOn -le $local:dateNow);
  }

  function Switch-SslMode() {
    Param(
      [ValidateNotNullOrWhiteSpace()]
      [ValidateSet("Off", "On")]
      [System.String]
      $Mode
    )
    $local:success = $False;
    $local:cloudflareKey = ((Get-Content -LiteralPath $CloudFlareSettings | Select-String "dns_cloudflare_api_key") -Replace "dns_cloudflare_api_key = ", "");
    $local:data = $Null;
    if ($Mode -eq "On") {
      $local:body = (@{
        value = "$($CloudFlareDefaultSsl)";
      } | ConvertTo-Json);
      $local:data = (Invoke-RestMethod -Method Patch -Uri "https://api.cloudflare.com/client/v4/zones/$($CloudFlareZone)/settings/ssl" -Headers @{
        "Content-Type" = "application/json";
        "X-Auth-Email" = "$($CloudFlareEmail)";
        "X-Auth-Key" = "$($local:cloudflareKey)";
      } -Body $local:body -ErrorAction Continue);
      If ($Null -ne $local:data -and $local:data.success) {
        $local:success = $True;
      } Else {
        If ($Null -eq $local:data) {
          $local:error = "Failed to run Invoke-WebRequest.";
        } Else {
          $local:error = "Failed to load data from CloudFlare Rest API.`n";
          $local:error += "errors:   $($local:data.errors.code) - $($local:data.errors.message)`n";
          $local:error += "messages: $($local:data.messages.code) - $($local:data.messages.message)";
          Write-Error -Message $local:error;
        }
      }
    } Else {
      $local:body = (@{
        value = "$($CloudFlareRenewSsl)";
      } | ConvertTo-Json);
      $local:data = (Invoke-RestMethod -Method Patch -Uri "https://api.cloudflare.com/client/v4/zones/$($CloudFlareZone)/settings/ssl" -Headers @{
        "Content-Type" = "application/json";
        "X-Auth-Email" = "$($CloudFlareEmail)";
        "X-Auth-Key" = "$($local:cloudflareKey)";
      } -Body $local:body -ErrorAction Continue);
      If ($Null -ne $local:data -and $local:data.success) {
        $local:success = $True;
      } Else {
        If ($Null -eq $local:data) {
          $local:error = "Failed to load data from CloudFlare Rest API.";
        } Else {
          $local:error = "Failed to load data from CloudFlare Rest API.`n";
          $local:error += "errors:   $($local:data.errors.code) - $($local:data.errors.message)`n";
          $local:error += "messages: $($local:data.messages.code) - $($local:data.messages.message)";
          Write-Error -Message $local:error;
        }
      }
    }

    Write-Output -NoEnumerate -InputObject $local:success;
  }

  function Invoke-ServiceNginx {
    Param (
      [ValidateNotNullOrWhiteSpace()]
      [ValidateSet("Stop", "Start")]
      [System.String]
      $Method
    )

    DynamicParam {
      $Method = $Method.ToLower();
    }
    Begin {
      $local:exitCode = 0;
    }
    Process {

      & "$($Service)" "nginx" "$($Method)";
      $local:exitCode = $LastExitCode;

      if ($local:exitCode -ne 0) {
        If ($Method -eq "stop") {
          $local:PIDs = @(Get-Process -Name "nginx*" -ErrorAction SilentlyContinue);

          ForEach ($Item in $local:PIDs) {
            Stop-Process -Id $Item.Id -Force -ErrorAction Continue;
            $local:tempExitCode = $LastExitCode
            If ($local:tempExitCode -ne 0) {
              $local:exitCode = $local:tempExitCode;
            }
          }
        }
      }
    }
    End {
      Write-Output -NoEnumerate -InputObject $local:exitCode;
    }
  }

  Function Invoke-ForDomain {
    Param(
      [ValidateNotNullOrWhiteSpace()]
      [System.String]
      $Domain
    )
    $local:exitCode = 0;

    Write-Debug -Message "`$Domain = $($Domain)";

    Write-Host -ForegroundColor Blue  -NoNewline -Object "Running certonly on domain: "
    Write-Host -ForegroundColor White            -Object "$($Domains)"

#   $local:Cmd = "$($CertBot) certonly --dns-cloudflare --dns-cloudflare-credentials=`"$($CloudFlareApi)`" -d $($Domain) -q"
#   $local:Cmd = "$($CertBot) certonly --dns-cloudflare --manual --preferred-challenges dns -d $($Domain) -q";
    $local:Cmd = "$($ACME) --debug 2 --ocsp-must-staple --keylength 4096 --renew --dns dns_cf $($Domain) --server letsencrypt --key-file /etc/letsencrypt/live/example.com/privkey.pem --fullchain-file /etc/letsencrypt/live/example.com/fullchain.pem"

    $local:data = (& "$($local:Cmd)");

    $local:exitCode = $LastExitCode

    If ($local:data -contains "Skip, Next renewal time is") {
      Write-Debug -Message "`$LastExitCode = `"$($local:exitCode)`"";
      Write-Output -NoEnumerate -InputObject 0;
    }

    Write-Output -NoEnumerate -InputObject $local:ExitCode;
  }

  Function Invoke-Renew {
    Param()
    $local:exitCode = 0;
    If ($CloudFlare -eq $True) {
#     $local:Domains = ((((& "$($CertBot)" certificates | Select-String -Pattern "Domains: .*\n.*\(VALID") -Replace "[ \t]*Domains: ", "") -Replace " *Expiry Date: [0-9]\+-[0-9]\+-[0-9]\+ [0-9]\+:[0-9]\+:[0-9]\++[0-9]\+:[0-9]\+ \(VALID", "") -Replace "\0", "")
      $local:Domains = @("example.com", "'*.example.com'");
      $local:Attached = "";
      $local:Expired = Test-SslExpire;

      If ($Expired -eq $False) {
        Write-Output -NoEnumerate -InputObject 0;
      }

      ForEach ($Domain in $local:Domains) {
        Write-Host -ForegroundColor Blue  -NoNewline -Object "`$domain = ";
        Write-Host -ForegroundColor White            -Object "$($Domain)";
        $local:Attached += "-d $($Domain) ";
      }
      Write-Host -ForegroundColor Blue  -NoNewline -Object "`$attached = ";
      Write-Host -ForegroundColor White            -Object "$($local:Attached)";
      $local:exitCode = (Invoke-ForDomain -Domain "$($Attached)");

      if ($local:exitCode -ne 0) {
        Write-Host -ForegroundColor Red   -NoNewline -Object "Had an error";
      } Else {
        Write-Host -ForegroundColor Green -NoNewline -Object "Completed successfully";
      }
    }
    Write-Output -NoEnumerate -InputObject $local:exitCode
  }


  #If ((Test-SslExpire) -eq $False) {
  #  Write-Warning -Message "SSL certificate is not expired."
  #  Exit 0
  #}
  #
  #$StopNginx = (Invoke-ServiceNginx -Method Stop);
  #If ($StopNginx -ne 0) {
  #  $ExitCode = $StopNginx;
  #}
  #
  #If ((Invoke-SwitchSslMode -Method "Off") -eq $False) {
  #  Write-Error -Message "Failed to switch ssl mode";
  #  Exit 1;
  #}

  $ExitCode = (Invoke-Renew);

  #If ($CloudFlare -ne $True) {
  #  Write-Host -Object "Running renew as `"Standalone`""
  #  & "$($CertBot)" renew --standalone
  #
  #  $ExitCode = $LastExitCode;
  #}
  #
  #If ((Invoke-SwitchSslMode -Method "On") -eq $False) {
  #  Write-Error -Message "Failed to switch ssl mode"
  #  Exit 1
  #}
}
End {
  If ($ExitCode -eq 0) {
    Write-Host -ForegroundColor Green -NoNewline -Object "Completed successfully";
  } else {
    Write-Host -ForegroundColor Red   -NoNewline -Object "Had an error";
  }

  $StopNginx = (Invoke-ServiceNginx -Method Stop);
  If ($StopNginx -ne 0) {
    $ExitCode = $StopNginx;
  }

  $StartNginx = (Invoke-ServiceNginx -Method Start);
  If ($StartNginx -ne 0) {
    $ExitCode = $StartNginx;
  }

  Write-Host -ForegroundColor Blue  -NoNewline -Object "Exit Code: ";
  Write-Host -ForegroundColor White            -Object "$($ExitCode)";
  Exit $ExitCode;
}