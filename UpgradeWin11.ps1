$dir = 'C:\temp\Win11'
mkdir $dir
$webClient = New-Object System.Net.WebClient
$url = 'https://go.microsoft.com/fwlink/?linkid=2171764'
$file = "$($dir)\Windows11InstallationAssistant.exe"
$webClient.DownloadFile($url,$file)
Start-Process -FilePath $file -ArgumentList "/quietinstall /skipeula /auto upgrade /NoRestartUI /copylogs $dir"
