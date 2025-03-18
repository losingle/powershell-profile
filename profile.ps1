oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/1_shell.omp.json" | Invoke-Expression

Import-Module posh-git
Import-Module PSReadLine
Import-Module Terminal-Icons

# PSReadLine 配置
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{
    Command            = 'Magenta'
    Parameter          = 'DarkGreen'
    InlinePrediction   = 'DarkGray'
}

# 初始化Conda环境
function Initialize-CondaEnvironment {
    # 常见的Conda安装路径
    $condaPaths = @(
        "D:\Developers\miniconda3",  # 优先检查自定义位置
        "$env:USERPROFILE\anaconda3",
        "$env:USERPROFILE\miniconda3",
        "C:\ProgramData\Anaconda3",
        "C:\ProgramData\miniconda3"
    )
    
    foreach ($path in $condaPaths) {
        $condaExe = Join-Path $path "Scripts\conda.exe"
        if (Test-Path $condaExe) {
            # 找到conda安装，初始化环境
            Write-Host "Initializing Conda from $path" -ForegroundColor Green
            
            # 初始化conda
            & "$path\Scripts\conda.exe" "shell.powershell" "hook" | Out-String | Invoke-Expression
            return $true
        }
    }
    
    return $false
}

# 尝试初始化Conda并设置全局变量
$global:CondaInitialized = Initialize-CondaEnvironment

# Python和Conda信息函数
function Get-PythonInfo {
    try {
        $pythonVersion = (python --version 2>&1).ToString().Replace("Python ", "")
        Write-Host "Python Version: " -ForegroundColor Cyan -NoNewline
        Write-Host "$pythonVersion" -ForegroundColor Green
        
        # 获取安装的包信息
        Write-Host "Installed Packages: " -ForegroundColor Cyan
        try {
            # 使用临时文件存储pip list的输出
            $tempFile = [System.IO.Path]::GetTempFileName()
            python -m pip list --format=columns | Out-File -FilePath $tempFile
            
            # 显示所有包
            Get-Content $tempFile | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
            
            # 清理临时文件
            Remove-Item $tempFile -Force
        }
        catch {
            Write-Host "  无法获取已安装的包列表: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Python information not available: $_" -ForegroundColor Red
    }
}
Set-Alias -Name pyinfo -Value Get-PythonInfo

function Get-CondaInfo {
    if (-not $global:CondaInitialized) {
        Write-Host "Conda is not initialized or installed" -ForegroundColor Red
        return
    }
    
    try {
        # 获取Conda版本
        $condaVersion = (conda --version 2>&1).ToString().Replace("conda ", "")
        Write-Host "Conda Version: " -ForegroundColor Cyan -NoNewline
        Write-Host "$condaVersion" -ForegroundColor Green
        
        # 使用临时文件存储conda环境列表
        $tempFile = [System.IO.Path]::GetTempFileName()
        conda env list | Out-File -FilePath $tempFile
        $envList = Get-Content $tempFile
        
        # 获取当前环境
        $currentEnv = $envList | Where-Object { $_ -match "^\*" }
        if ($currentEnv) {
            Write-Host "Current Environment: " -ForegroundColor Cyan -NoNewline
            Write-Host "$currentEnv" -ForegroundColor Yellow
        } else {
            Write-Host "Current Environment: " -ForegroundColor Cyan -NoNewline
            Write-Host "None active" -ForegroundColor Yellow
        }
        
        # 获取所有环境
        Write-Host "Available Environments: " -ForegroundColor Cyan
        $envList | Where-Object { $_ -notmatch "^\#" -and $_.Trim() -ne "" } | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        # 清理临时文件
        Remove-Item $tempFile -Force
    }
    catch {
        Write-Host "Error retrieving conda information: $_" -ForegroundColor Red
    }
}
Set-Alias -Name condainfo -Value Get-CondaInfo

# 激活Conda环境的快捷函数
function Set-CondaEnvironment {
    param (
        [Parameter(Mandatory=$true)]
        [string]$EnvName
    )
    
    if (-not $global:CondaInitialized) {
        Write-Host "Conda is not initialized or installed" -ForegroundColor Red
        return
    }
    
    try {
        # 检查环境是否存在
        $envExists = conda env list | Where-Object { $_ -match "\b$EnvName\b" }
        if (-not $envExists) {
            Write-Host "Conda environment '$EnvName' not found" -ForegroundColor Red
            return
        }
        
        # 激活环境
        conda activate $EnvName
        Write-Host "Activated conda environment: " -ForegroundColor Cyan -NoNewline
        Write-Host "$EnvName" -ForegroundColor Green
    }
    catch {
        Write-Host "Error activating conda environment: $_" -ForegroundColor Red
    }
}
Set-Alias -Name condaenv -Value Set-CondaEnvironment

function Show-DevEnvironment {
    Write-Host "`n===== 开发环境信息 =====" -ForegroundColor Magenta
    Get-PythonInfo
    Write-Host ""
    Get-CondaInfo
    Write-Host "======================" -ForegroundColor Magenta
}
Set-Alias -Name devenv -Value Show-DevEnvironment

# 快速列出所有Conda环境
function Get-CondaEnvironments {
    if (-not $global:CondaInitialized) {
        Write-Host "Conda is not initialized or installed" -ForegroundColor Red
        return
    }
    
    try {
        Write-Host "Available Conda Environments:" -ForegroundColor Cyan
        conda env list
    }
    catch {
        Write-Host "Error listing conda environments: $_" -ForegroundColor Red
    }
}
Set-Alias -Name cenvs -Value Get-CondaEnvironments

# 创建新的Conda环境的便捷函数
function New-CondaEnvironment {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$PythonVersion = "3.9",
        
        [Parameter(Mandatory=$false)]
        [switch]$WithTorch,
        
        [Parameter(Mandatory=$false)]
        [switch]$WithTensorflow,
        
        [Parameter(Mandatory=$false)]
        [switch]$WithJupyter
    )
    
    if (-not $global:CondaInitialized) {
        Write-Host "Conda is not initialized or installed" -ForegroundColor Red
        return
    }
    
    try {
        # 基本创建命令
        $createCmd = "conda create -n $Name python=$PythonVersion -y"
        Write-Host "Creating conda environment '$Name' with Python $PythonVersion..." -ForegroundColor Cyan
        Invoke-Expression $createCmd
        
        # 安装额外的包
        if ($WithTorch) {
            Write-Host "Installing PyTorch..." -ForegroundColor Cyan
            conda install -n $Name pytorch torchvision torchaudio -c pytorch -y
        }
        
        if ($WithTensorflow) {
            Write-Host "Installing TensorFlow..." -ForegroundColor Cyan
            conda install -n $Name tensorflow -y
        }
        
        if ($WithJupyter) {
            Write-Host "Installing Jupyter..." -ForegroundColor Cyan
            conda install -n $Name jupyter notebook -y
        }
        
        Write-Host "Conda environment '$Name' created successfully!" -ForegroundColor Green
        Write-Host "To activate, run: " -NoNewline
        Write-Host "conda activate $Name" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error creating conda environment: $_" -ForegroundColor Red
    }
}
Set-Alias -Name conda-create -Value New-CondaEnvironment

#region 快速导航函数集合
# 导航到项目目录
function Go-ProjectDir { 
    param (
        [Parameter(Mandatory=$false)]
        [string]$ProjectName
    )
    
    $projectDir = "$env:USERPROFILE\Projects"
    
    # 确保项目目录存在
    if (-not (Test-Path $projectDir)) {
        Write-Host "Projects directory does not exist. Creating it..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $projectDir | Out-Null
    }
    
    # 如果指定了项目名称，则导航到特定项目
    if ($ProjectName) {
        $specificProject = Join-Path $projectDir $ProjectName
        if (Test-Path $specificProject) {
            Set-Location -Path $specificProject
            Write-Host "Navigated to project: $ProjectName" -ForegroundColor Green
        } else {
            Write-Host "Project '$ProjectName' not found. Available projects:" -ForegroundColor Yellow
            Get-ChildItem -Path $projectDir -Directory | ForEach-Object {
                Write-Host "  - $($_.Name)" -ForegroundColor Cyan
            }
        }
    } else {
        # 否则导航到项目根目录
        Set-Location -Path $projectDir
        Write-Host "Navigated to Projects directory. Available projects:" -ForegroundColor Green
        Get-ChildItem -Path $projectDir -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Cyan
        }
    }
}
Set-Alias -Name proj -Value Go-ProjectDir
Set-Alias -Name cdp -Value Go-ProjectDir

# 导航到文档目录
function Go-DocumentsDir {
    $docsDir = [Environment]::GetFolderPath("MyDocuments")
    Set-Location -Path $docsDir
    Write-Host "Navigated to Documents directory" -ForegroundColor Green
}
Set-Alias -Name docs -Value Go-DocumentsDir

# 导航到下载目录
function Go-DownloadsDir {
    $downloadsDir = Join-Path $env:USERPROFILE "Downloads"
    Set-Location -Path $downloadsDir
    Write-Host "Navigated to Downloads directory" -ForegroundColor Green
}
Set-Alias -Name dl -Value Go-DownloadsDir

# 导航到桌面
function Go-DesktopDir {
    $desktopDir = [Environment]::GetFolderPath("Desktop")
    Set-Location -Path $desktopDir
    Write-Host "Navigated to Desktop directory" -ForegroundColor Green
}
Set-Alias -Name desk -Value Go-DesktopDir

# 导航到用户主目录
function Go-HomeDir {
    Set-Location -Path $env:USERPROFILE
    Write-Host "Navigated to Home directory" -ForegroundColor Green
}
Set-Alias -Name home -Value Go-HomeDir

# 导航到当前PowerShell配置文件目录
function Go-PSProfileDir {
    $profileDir = Split-Path -Parent $PROFILE
    Set-Location -Path $profileDir
    Write-Host "Navigated to PowerShell profile directory" -ForegroundColor Green
}
Set-Alias -Name psdir -Value Go-PSProfileDir

# 显示所有可用的导航命令
function Show-NavigationCommands {
    Write-Host "Available Navigation Commands:" -ForegroundColor Magenta
    Write-Host "  proj [ProjectName] - Navigate to Projects directory or specific project" -ForegroundColor Cyan
    Write-Host "  cdp [ProjectName]  - Alias for proj command" -ForegroundColor Cyan
    Write-Host "  docs               - Navigate to Documents directory" -ForegroundColor Cyan
    Write-Host "  dl                 - Navigate to Downloads directory" -ForegroundColor Cyan
    Write-Host "  desk               - Navigate to Desktop directory" -ForegroundColor Cyan
    Write-Host "  home               - Navigate to Home directory" -ForegroundColor Cyan
    Write-Host "  psdir              - Navigate to PowerShell profile directory" -ForegroundColor Cyan
}
Set-Alias -Name navhelp -Value Show-NavigationCommands


# 自定义别名
Set-Alias g git
Set-Alias ll Get-ChildItem

# 自定义函数
function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}