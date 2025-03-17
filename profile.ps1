#region conda initialize
# 自动检测 conda 安装路径
function Get-CondaPath {
    $possiblePaths = @(
        "D:\Developers\miniconda3",  # 优先检查自定义位置
        "$env:USERPROFILE\miniconda3",
        "$env:USERPROFILE\anaconda3",
        "$env:LOCALAPPDATA\miniconda3",
        "$env:LOCALAPPDATA\anaconda3",
        "$env:PROGRAMFILES\miniconda3",
        "$env:PROGRAMFILES\anaconda3"
    )
    
    foreach ($path in $possiblePaths) {
        $condaExePath = Join-Path $path "Scripts\conda.exe"
        if (Test-Path $condaExePath) {
            return $condaExePath
        }
    }
    
    return $null
}

#region 显示系统启动信息
function Show-SystemInfo {
    # 获取控制台宽度，确保表格合适显示
    try {
        $consoleWidth = [Console]::WindowWidth
    }
    catch {
        # 如果无法获取控制台宽度，使用默认值
        $consoleWidth = 100
    }
    
    # 计算最佳宽度：最大值为控制台宽度-2，最小值为80，默认值为100
    $bannerWidth = [Math]::Min([Math]::Max(80, $consoleWidth - 2), 100)
    
    # 获取系统信息
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $memoryInfo = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
        $freeMemory = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
    }
    catch {
        $osInfo = $null
        $memoryInfo = 0
        $freeMemory = 0
    }
    
    # 获取GPU信息
    function Get-GpuInfo {
        try {
            # 使用 WMI 查询获取所有显卡信息
            $videoControllers = Get-CimInstance -ClassName Win32_VideoController
            $gpuInfo = @()
            
            foreach ($gpu in $videoControllers) {
                $gpuInfo += [PSCustomObject]@{
                    Name = $gpu.Name
                    DriverVersion = $gpu.DriverVersion
                    Memory = if ($gpu.AdapterRAM) { 
                        [math]::Round($gpu.AdapterRAM / 1GB, 2).ToString() + " GB" 
                    } else { 
                        "Unknown" 
                    }
                    Status = $gpu.Status
                }
            }
            
            return $gpuInfo
        }
        catch {
            return @([PSCustomObject]@{
                Name = "Unable to retrieve GPU information"
                DriverVersion = "N/A"
                Memory = "N/A"
                Status = "Error"
            })
        }
    }

    # 获取CUDA信息
    function Get-CudaInfo {
        try {
            # 检查是否存在nvidia-smi
            $nvidiaSmi = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
            if ($nvidiaSmi) {
                $nvidiaSmiOutput = & nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free,temperature.gpu,utilization.gpu,compute_mode --format=csv,noheader
                if ($nvidiaSmiOutput) {
                    $gpus = @()
                    foreach ($line in $nvidiaSmiOutput) {
                        $values = $line -split ', '
                        if ($values.Count -ge 7) {
                            $gpus += [PSCustomObject]@{
                                Name = $values[0]
                                DriverVersion = $values[1]
                                TotalMemory = $values[2]
                                FreeMemory = $values[3]
                                Temperature = $values[4]
                                Utilization = $values[5]
                                ComputeMode = $values[6]
                            }
                        }
                    }
                    return $gpus
                }
            }
            
            # 如果nvidia-smi不可用，回退到WMI信息
            return Get-GpuInfo
        }
        catch {
            return Get-GpuInfo
        }
    }
    
    # 优化的文本处理函数，更好地处理长文本行
    function Write-InfoLine {
        param (
            [string]$Label,
            [string]$Value,
            [string]$Color = "White",
            [int]$LabelWidth = 10,
            [int]$Indent = 0
        )
        
        $indentString = " " * $Indent
        $labelText = "$indentString$Label".PadRight($LabelWidth + $Indent)
        $valueText = ": $Value"
        
        # 计算可用于显示值的最大宽度
        $maxValueWidth = $bannerWidth - $LabelWidth - $Indent - 4 # 4 = "│ " + ": " + " │"
        
        # 显示标签部分
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host $labelText -NoNewline -ForegroundColor $(if ($Indent -eq 0) { "DarkYellow" } else { "DarkCyan" })
        
        if ($valueText.Length -le $maxValueWidth) {
            # 文本不长，正常显示
            Write-Host $valueText.PadRight($maxValueWidth) -NoNewline -ForegroundColor $Color
            Write-Host " │" -ForegroundColor DarkGray
        } else {
            # 文本过长，需要拆分显示
            $firstLine = $valueText.Substring(0, $maxValueWidth)
            Write-Host $firstLine -NoNewline -ForegroundColor $Color
            Write-Host " │" -ForegroundColor DarkGray
            
            # 处理剩余文本
            $remainingText = $valueText.Substring($maxValueWidth)
            $continuationIndent = $LabelWidth + $Indent
            
            while ($remainingText.Length -gt 0) {
                $lineLength = [Math]::Min($remainingText.Length, $bannerWidth - $continuationIndent - 5) # 5 = "│ " + " │"
                $line = $remainingText.Substring(0, $lineLength)
                
                if ($remainingText.Length -gt $lineLength) {
                    $remainingText = $remainingText.Substring($lineLength)
                } else {
                    $remainingText = ""
                }
                
                Write-Host "│ " -NoNewline -ForegroundColor DarkGray
                Write-Host "".PadRight($continuationIndent) -NoNewline
                Write-Host $line.PadRight($bannerWidth - $continuationIndent - 5) -NoNewline -ForegroundColor $Color
                Write-Host " │" -ForegroundColor DarkGray
            }
        }
    }

    # 计算标题宽度和边框
    $horizontalBorder = "─" * ($bannerWidth - 2)
    
    Write-Host "╭$horizontalBorder╮" -ForegroundColor DarkGray
    
    # 优化标题居中逻辑
    $title = "System Information"
    $titleLength = $title.Length
    $leftPadding = [math]::Floor(($bannerWidth - $titleLength - 2) / 2)
    $rightPadding = $bannerWidth - $titleLength - $leftPadding - 2
    
    Write-Host "│" -NoNewline -ForegroundColor DarkGray
    Write-Host "$(" " * $leftPadding)" -NoNewline
    Write-Host $title -NoNewline -ForegroundColor White
    Write-Host "$(" " * $rightPadding)" -NoNewline
    Write-Host "│" -ForegroundColor DarkGray
    
    # 操作系统信息
    if ($osInfo) {
        Write-InfoLine -Label "OS" -Value "$($osInfo.Caption) ($($osInfo.Version))"
    } else {
        Write-InfoLine -Label "OS" -Value "Unable to retrieve OS information"
    }
    
    # CPU信息
    try {
        # 获取所有CPU
        $cpus = Get-CimInstance -ClassName Win32_Processor
        
        # 计算核心和线程总数
        $totalCores = 0
        $totalThreads = 0
        foreach ($cpu in $cpus) {
            $totalCores += $cpu.NumberOfCores
            $totalThreads += $cpu.NumberOfLogicalProcessors
        }
        
        # 显示CPU信息
        if ($cpus.Count -eq 1) {
            Write-InfoLine -Label "CPU" -Value "$($cpus[0].Name) ($totalCores cores, $totalThreads threads)"
        } else {
            Write-InfoLine -Label "CPUs" -Value "$($cpus.Count) processors ($totalCores cores, $totalThreads threads)"
            
            # 显示每个处理器
            $cpuNum = 1
            foreach ($cpu in $cpus) {
                Write-InfoLine -Label "CPU $cpuNum" -Value "$($cpu.Name) ($($cpu.NumberOfCores) cores)" -Indent 2 -LabelWidth 8
                $cpuNum++
            }
        }
    }
    catch {
        Write-InfoLine -Label "CPU" -Value "Unable to retrieve CPU information"
    }
    
    # 内存信息
    if ($memoryInfo -gt 0) {
        Write-InfoLine -Label "Memory" -Value "$freeMemory GB free of $memoryInfo GB"
    } else {
        Write-InfoLine -Label "Memory" -Value "Unable to retrieve memory information"
    }
    
    # GPU信息
    try {
        $gpus = Get-CudaInfo
        
        if ($gpus.Count -gt 0) {
            if ($gpus.Count -eq 1) {
                Write-InfoLine -Label "GPU" -Value "$($gpus[0].Name)"
                
                # 显示GPU详细信息
                if ($gpus[0].DriverVersion -ne "N/A") {
                    Write-InfoLine -Label "Driver" -Value "$($gpus[0].DriverVersion)" -Indent 2 -LabelWidth 8
                }
                
                # 显示GPU内存信息
                if (($gpus[0].PSObject.Properties.Name -contains "TotalMemory") -and ($gpus[0].TotalMemory -ne "N/A")) {
                    Write-InfoLine -Label "Memory" -Value "$($gpus[0].FreeMemory) free of $($gpus[0].TotalMemory)" -Indent 2 -LabelWidth 8
                } elseif ($gpus[0].Memory -ne "N/A" -and $gpus[0].Memory -ne "Unknown") {
                    Write-InfoLine -Label "Memory" -Value "$($gpus[0].Memory)" -Indent 2 -LabelWidth 8
                }
                
                # 显示GPU利用率
                if (($gpus[0].PSObject.Properties.Name -contains "Utilization") -and ($gpus[0].Utilization -ne "N/A")) {
                    Write-InfoLine -Label "Usage" -Value "$($gpus[0].Utilization)" -Indent 2 -LabelWidth 8
                }
                
                # 显示GPU温度
                if (($gpus[0].PSObject.Properties.Name -contains "Temperature") -and ($gpus[0].Temperature -ne "N/A")) {
                    Write-InfoLine -Label "Temp" -Value "$($gpus[0].Temperature)" -Indent 2 -LabelWidth 8
                }
            } else {
                # 多GPU情况
                Write-InfoLine -Label "GPUs" -Value "$($gpus.Count) graphics adapters"
                
                # 显示每个GPU的信息
                for ($i = 0; $i -lt $gpus.Count; $i++) {
                    $gpu = $gpus[$i]
                    
                    Write-InfoLine -Label "GPU $($i)" -Value "$($gpu.Name)" -Indent 2 -LabelWidth 8
                    
                    if ($gpu.DriverVersion -ne "N/A") {
                        Write-InfoLine -Label "Driver" -Value "$($gpu.DriverVersion)" -Indent 4 -LabelWidth 6
                    }
                    
                    # 显示GPU内存信息
                    if (($gpu.PSObject.Properties.Name -contains "TotalMemory") -and ($gpu.TotalMemory -ne "N/A")) {
                        Write-InfoLine -Label "Memory" -Value "$($gpu.FreeMemory) free of $($gpu.TotalMemory)" -Indent 4 -LabelWidth 6
                    } elseif ($gpu.Memory -ne "N/A" -and $gpu.Memory -ne "Unknown") {
                        Write-InfoLine -Label "Memory" -Value "$($gpu.Memory)" -Indent 4 -LabelWidth 6
                    }
                    
                    # 显示GPU利用率
                    if (($gpu.PSObject.Properties.Name -contains "Utilization") -and ($gpu.Utilization -ne "N/A")) {
                        Write-InfoLine -Label "Usage" -Value "$($gpu.Utilization)" -Indent 4 -LabelWidth 6
                    }
                    
                    # 显示GPU温度
                    if (($gpu.PSObject.Properties.Name -contains "Temperature") -and ($gpu.Temperature -ne "N/A")) {
                        Write-InfoLine -Label "Temp" -Value "$($gpu.Temperature)" -Indent 4 -LabelWidth 6
                    }
                }
            }
        }
    }
    catch {
        Write-InfoLine -Label "GPU" -Value "Unable to retrieve GPU information"
    }
    
    # PowerShell版本
    Write-InfoLine -Label "PowerShell" -Value "$($PSVersionTable.PSVersion)"
    
    # Conda信息 - 只在有conda环境时显示
    if ($env:CONDA_DEFAULT_ENV) {
        Write-InfoLine -Label "Conda" -Value "Active environment: $env:CONDA_DEFAULT_ENV" -Color "Green"
    }
    
    # 日期和时间信息
    $currentDateTime = Get-Date
    $datetimeInfo = $currentDateTime.ToString("yyyy-MM-dd HH:mm:ss")
    Write-InfoLine -Label "DateTime" -Value "$datetimeInfo"
    
    # 尝试获取CUDA/cuDNN信息 - 只在有Python环境时尝试
    try {
        $pythonAvailable = Get-Command "python" -ErrorAction SilentlyContinue
        $nvidiaSmiAvailable = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
        
        if ($nvidiaSmiAvailable -or $pythonAvailable) {
            $cudaVersion = "Not detected"
            $cudnnVersion = "Not detected"
            
            # 尝试从NVIDIA-SMI获取CUDA版本
            if ($nvidiaSmiAvailable) {
                $nvidiaSmiOutput = & nvidia-smi
                if ($nvidiaSmiOutput -match "CUDA Version: (\d+\.\d+)") {
                    $cudaVersion = $matches[1]
                }
            }
            
            # 尝试从Python检测CUDA/cuDNN版本 - 只在有Python时尝试
            if ($pythonAvailable) {
                $pythonCommand = @"
try:
    import torch
    if torch.cuda.is_available():
        print(f"CUDA_VERSION={torch.version.cuda}")
        if hasattr(torch.backends.cudnn, 'version'):
            print(f"CUDNN_VERSION={torch.backends.cudnn.version()}")
except:
    try:
        import tensorflow as tf
        if tf.test.is_gpu_available():
            print(f"CUDA_VERSION={tf.sysconfig.get_build_info()['cuda_version']}")
            print(f"CUDNN_VERSION={tf.sysconfig.get_build_info()['cudnn_version']}")
    except:
        pass
"@
                $pythonResult = python -c $pythonCommand 2>$null
                
                if ($pythonResult) {
                    foreach ($line in $pythonResult) {
                        if ($line -match "CUDA_VERSION=(.+)") {
                            $cudaVersion = $matches[1]
                        }
                        if ($line -match "CUDNN_VERSION=(.+)") {
                            $cudnnVersion = $matches[1]
                        }
                    }
                }
            }
            
            # 如果检测到CUDA版本，显示出来
            if ($cudaVersion -ne "Not detected") {
                Write-InfoLine -Label "CUDA" -Value "$cudaVersion" -Color "Cyan"
                
                # 如果检测到cuDNN版本，也显示出来
                if ($cudnnVersion -ne "Not detected") {
                    Write-InfoLine -Label "cuDNN" -Value "$cudnnVersion" -Color "Cyan"
                }
            }
        }
    } catch {
        # 如果CUDA检测失败，忽略错误，不显示相关信息
    }
    
    Write-Host "╰$horizontalBorder╯" -ForegroundColor DarkGray
}

#region 初始化

# 设置一个变量来跟踪是否是第一次启动终端
$global:FirstTimeLoad = $true

# 获取PowerShell版本
$PSVersion = $PSVersionTable.PSVersion.ToString()

# 获取Conda路径函数
function Get-CondaPath {
    # 检查常见的Conda安装路径
    $condaPaths = @(
        "D:\Developers\miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\anaconda3\Scripts\conda.exe",
        "$env:PROGRAMFILES\miniconda3\Scripts\conda.exe",
        "$env:PROGRAMFILES\anaconda3\Scripts\conda.exe"
    )
    
    foreach ($path in $condaPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

# 获取Conda路径并初始化
$condaPath = Get-CondaPath
if ($condaPath) {
    try {
        # 初始化Conda
        $condaInitScript = Join-Path (Split-Path -Parent (Split-Path -Parent $condaPath)) "shell" "condabin" "conda-hook.ps1"
        if (Test-Path $condaInitScript) {
            . $condaInitScript
            # 添加Conda到PATH
            $condaRoot = Split-Path -Parent (Split-Path -Parent $condaPath)
            $env:PATH = "$condaRoot;$condaRoot\Scripts;$condaRoot\Library\bin;$env:PATH"
            # 设置Conda初始化信息
            $global:CondaInitialized = $true
            $global:CondaPath = $condaRoot
            Write-Host "Conda initialized from: $condaRoot" -ForegroundColor Green
        } else {
            $global:CondaInitialized = $false
            Write-Host "Conda initialization script not found at: $condaInitScript" -ForegroundColor Yellow
        }
    } catch {
        $global:CondaInitialized = $false
        Write-Host "Error initializing Conda: $_" -ForegroundColor Red
    }
} else {
    $global:CondaInitialized = $false
}

# 显示欢迎信息和系统信息（只在第一次启动终端时显示）
if ($global:FirstTimeLoad) {
    Clear-Host
    Write-Host ""
    Show-SystemInfo
    Write-Host ""
    # 设置标志，表示已经显示过系统信息
    $global:FirstTimeLoad = $false
}

#endregion

#region 自定义提示符
function prompt {
    # 获取上一个命令的执行结果
    $lastCommandSuccess = $?
    
    # 获取当前路径
    $currentPath = Get-Location
    
    # 获取当前时间
    $currentTime = Get-Date -Format "HH:mm:ss"
    
    # 获取当前Conda环境
    $condaEnv = ""
    if ($global:CondaInitialized) {
        $condaEnv = if ($env:CONDA_DEFAULT_ENV) { "($env:CONDA_DEFAULT_ENV) " } else { "" }
    }
    
    # 构建提示符
    # 显示时间信息
    Write-Host "$currentTime " -NoNewline -ForegroundColor Cyan
    
    # 显示 conda 环境
    if ($condaEnv) {
        Write-Host "$condaEnv" -NoNewline -ForegroundColor Green
    }
    
    # 显示 PowerShell 版本
    Write-Host "PS $PSVersion " -NoNewline -ForegroundColor Magenta
    
    # 显示用户名和主机名
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor DarkGreen
    Write-Host "@" -NoNewline
    Write-Host "$env:COMPUTERNAME " -NoNewline -ForegroundColor DarkYellow
    
    # 显示当前路径
    Write-Host "$currentPath" -NoNewline -ForegroundColor Blue
    
    # 在新行返回提示符，使命令有更多空间
    Write-Host ""
    
    # 返回提示符
    if ($lastCommandSuccess) {
        Write-Host "$ " -NoNewline -ForegroundColor Green
    } else {
        Write-Host "$ " -NoNewline -ForegroundColor Red
    }
    
    return " "
}
#endregion

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

# 添加reload!命令，用于刷新系统信息
function Reload-SystemInfo {
    Clear-Host
    Write-Host ""
    Show-SystemInfo
    Write-Host ""
}
Set-Alias -Name reload! -Value Reload-SystemInfo
#endregion