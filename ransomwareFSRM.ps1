$decryptreadme = (Invoke-WebRequest "https://raw.githubusercontent.com/csmithendsight/ransomware/readme.txt").Content

$fileexts = (Invoke-WebRequest "https://raw.githubusercontent.com/csmithendsight/ransomware/extensions.txt").Content

$filescreengroup = @()

foreach($line in $decryptreadme.Split("`r`n")){ if ($line -ne "") {$filescreengroup += $line} }
  foreach($line in $fileexts.Split("`r`n")){ if ($line -ne "") {$filescreengroup += $line} }

Get-FsrmFileGroup "CryptowareDEV" | Set-FsrmFileGroup -IncludePattern $filescreengroup
