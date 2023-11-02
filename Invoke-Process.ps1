Function Invoke-Process {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $False, Position = 0)]
        [String]$FileName = "PowerShell.exe",

        [Parameter(Mandatory = $False, Position = 1)]
        [String]$Arguments = "",

        [Parameter(Mandatory = $False, Position = 2)]
        [String]$WorkingDirectory = ".",

        [Parameter(Mandatory = $False, Position = 3)]
        [TimeSpan]$Timeout = [System.TimeSpan]::FromMinutes(2),

        [Parameter(Mandatory = $False, Position = 4)]
        [System.Diagnostics.ProcessPriorityClass]$Priority = [System.Diagnostics.ProcessPriorityClass]::Normal
    )

    end {
        try {
            # new Process
            $Process = NewProcess -FileName $FileName -Arguments $Arguments -WorkingDirectory $WorkingDirectory

            # Event Handler for Output
            $StdStringBuilder = New-Object -TypeName System.Text.StringBuilder
            $ErrorStringBuilder = New-Object -TypeName System.Text.StringBuilder
            $ScripBlock =
            {
                $RetrunData = $Event.SourceEventArgs.Data
                if (-not [String]::IsNullOrEmpty($RetrunData)) {
                    [System.Console]::WriteLine($RetrunData)
                    $Event.MessageData.AppendLine($RetrunData)
                }
            }
            $StdEvent = Register-ObjectEvent -InputObject $Process -EventName OutputDataReceived -Action $ScripBlock -MessageData $StdStringBuilder
            $ErrorEvent = Register-ObjectEvent -InputObject $Process -EventName ErrorDataReceived -Action $ScripBlock -MessageData $ErrorStringBuilder

            # execution
            $Process.Start() > $null
            $Process.PriorityClass = $Priority
            $Process.BeginOutputReadLine()
            $Process.BeginErrorReadLine()

            # wait for complete
            "Waiting for command complete. It will Timeout in {0}ms" -f $Timeout.TotalMilliseconds | VerboseOutput
            $IsTimeout = $False
            if (-not $Process.WaitForExit($Timeout.TotalMilliseconds)) {
                $IsTimeout = $True
                "Timeout detected for {0}ms. Kill process immediately" -f $Timeout.TotalMilliseconds | VerboseOutput
                $Process.Kill()
            }
            $Process.WaitForExit()
            $Process.CancelOutputRead()
            $Process.CancelErrorRead()

            # verbose Event Result
            $StdEvent, $ErrorEvent | VerboseOutput

            # Unregister Event to recieve Asynchronous Event output (You should call before process.Dispose())
            Unregister-Event -SourceIdentifier $StdEvent.Name
            Unregister-Event -SourceIdentifier $ErrorEvent.Name

            # verbose Event Result
            $StdEvent, $ErrorEvent | VerboseOutput

            # Get Process result
            Return GetCommandResult -Process $Process -StandardStringBuilder $StdStringBuilder -ErrorStringBuilder $ErrorStringBuilder -IsTimeOut $IsTimeout
        } finally {
            if ($null -ne $Process) { $Process.Dispose() }
            if ($null -ne $StdEvent) { $StdEvent.StopJob(); $StdEvent.Dispose() }
            if ($null -ne $ErrorEvent) { $ErrorEvent.StopJob(); $ErrorEvent.Dispose() }
        }
    }

    begin {
        Function NewProcess {
            [OutputType([System.Diagnostics.Process])]
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory = $True)]
                [String]$FileName,

                [Parameter(Mandatory = $False)]
                [String]$Arguments,

                [Parameter(Mandatory = $False)]
                [String]$WorkingDirectory
            )

            "Execute command : '{0} {1}', WorkingSpace '{2}'" -f $FileName, $Arguments, $WorkingDirectory | VerboseOutput
            # ProcessStartInfo
            $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessStartInfo.CreateNoWindow = $True
            $ProcessStartInfo.LoadUserProfile = $True
            $ProcessStartInfo.UseShellExecute = $False
            $ProcessStartInfo.RedirectStandardOutput = $True
            $ProcessStartInfo.RedirectStandardError = $True
            $ProcessStartInfo.FileName = $FileName
            $ProcessStartInfo.Arguments += $Arguments
            $ProcessStartInfo.WorkingDirectory = $WorkingDirectory

            # Set Process
            $Process = New-Object System.Diagnostics.Process
            $Process.StartInfo = $ProcessStartInfo
            $Process.EnableRaisingEvents = $True
            Return $Process
        }

        Function GetCommandResult {
            [OutputType([PSCustomObject])]
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory = $True)]
                [System.Diagnostics.Process]$Process,

                [Parameter(Mandatory = $True)]
                [System.Text.StringBuilder]$StandardStringBuilder,

                [Parameter(Mandatory = $True)]
                [System.Text.StringBuilder]$ErrorStringBuilder,

                [Parameter(Mandatory = $True)]
                [Bool]$IsTimeout
            )

            'Get command result String.' | VerboseOutput
            Return [PSCustomObject]@{
                StandardOutput = $StandardStringBuilder.ToString().Trim()
                ErrorOutput    = $ErrorStringBuilder.ToString().Trim()
                ExitCode       = $Process.ExitCode
                IsTimeOut      = $IsTimeout
            }
        }

        filter VerboseOutput {
            $_ | Out-String -Stream | Write-Verbose
        }
    }
}
