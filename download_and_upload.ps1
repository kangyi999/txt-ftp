# download_and_upload.ps1
# 每个源配置：下载链接、本地文件名、FTP远端目录
$urlList = @(
    @{
        url="https://raw.githubusercontent.com/kangyi888/iptv-auto/main/output/out1.m3u"
        localName="fy01.txt"
        ftpDir="fy"
    },
    @{
        url="https://raw.githubusercontent.com/kangyi888/iptv-auto/main/output/out3.txt"
        localName="ky01.txt"
        ftpDir="ky"
    }
)

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

# 下载文件
foreach($item in $urlList){
    $url = $item.url
    $outFile = $item.localName
    $success = $false
    # 最多重试1次
    for($try=0;$try -le 1;$try++){
        try{
            Write-Host "Attempt $($try+1): Download $url -> $outFile"
            Invoke-WebRequest -Uri $url -OutFile $outFile -Headers $headers -TimeoutSec 30 -UseBasicParsing
            $success = $true
            Write-Host "Download OK: $outFile"
            break
        }catch{
            Write-Host "Attempt $($try+1) failed: $_"
            Start-Sleep -Seconds 2
        }
    }
    if(-not $success){
        Write-Host "All retry failed for $url, skip this file"
    }
}

# ========== FTP上传部分 ==========
$ftpHost = $env:FTP_HOST
$ftpUser = $env:FTP_USER
$ftpPass = $env:FTP_PASS

$securePass = ConvertTo-SecureString $ftpPass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($ftpUser, $securePass)

foreach($item in $urlList){
    $localFile = $item.localName
    $remoteSubDir = $item.ftpDir
    if(-not (Test-Path $localFile)){
        Write-Host "File $localFile not found, skip upload"
        continue
    }
    # 拼接FTP地址：ftp://服务器/子目录/文件名
    $ftpFullPath = "ftp://$ftpHost/$remoteSubDir/$localFile"
    Write-Host "Uploading $localFile to $ftpFullPath"
    try{
        $webClient = New-Object System.Net.WebClient
        $webClient.Credentials = $cred
        $webClient.UploadFile($ftpFullPath, $localFile)
        Write-Host "Upload success: $localFile"
        $webClient.Dispose()
    }catch{
        Write-Host "Upload failed $localFile : $_"
    }
}

