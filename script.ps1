# URL and Destination
$url = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"
$dest = "C:\Users\Peyton Pulliam\Downloads"
# Define username and password
$username = 'Peyton Pulliam'
$password = 'scottwaites'
# Convert to SecureString
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
# Create Credential Object
$credObject = New-Object System.Management.Automation.PSCredential ($username, $secPassword)
# Download file
Invoke-WebRequest -Uri $url -OutFile $dest -Credential $credObject
