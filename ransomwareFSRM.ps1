$decryptreadme = (Invoke-WebRequest "https://raw.githubusercontent.com/endsight/ransomware/master/$readme.txt").Content

$fileexts = (Invoke-WebRequest "https://raw.githubusercontent.com/endsight/ransomware/master/$extensions.txt").Content

$filescreengroup = @()

foreach($line in $decryptreadme.Split("`r`n")){ if ($line -ne "") {$filescreengroup += $line} }
  foreach($line in $fileexts.Split("`r`n")){ if ($line -ne "") {$filescreengroup += $line} }

Get-FsrmFileGroup "CryptoDev" | Set-FsrmFileGroup -IncludePattern $filescreengroup
