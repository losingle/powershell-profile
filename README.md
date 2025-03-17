# PowerShell 增强配置文件

这个PowerShell配置文件提供了一系列实用功能，包括系统信息显示、快速导航、Conda环境管理等，旨在提升您的PowerShell使用体验。

## 功能概览

- **系统信息显示**：美观的系统信息表格，显示操作系统、CPU、内存、GPU等详细信息
- **快速导航**：一系列命令用于快速导航到常用目录
- **Conda环境管理**：自动检测并初始化Conda环境（如果已安装）
- **自定义提示符**：增强的PowerShell提示符，显示时间、Conda环境和路径信息

## 安装指南

1. 将此仓库克隆到您的计算机上：
   ```powershell
   git clone https://github.com/yourusername/profiles-info.git
   ```

2. 将配置文件链接到您的PowerShell配置文件位置：
   ```powershell
   # 查看您的PowerShell配置文件路径
   echo $PROFILE
   
   # 创建符号链接（管理员权限）
   New-Item -ItemType SymbolicLink -Path $PROFILE -Target "路径\到\profiles-info\profile.ps1" -Force
   ```

3. 重启PowerShell或重新加载配置文件：
   ```powershell
   . $PROFILE
   ```

### 安装Conda（可选）

如果您想使用Conda相关功能，需要先安装Miniconda或Anaconda：

1. **安装Miniconda**（推荐，体积较小）:
   - 访问 [Miniconda官网](https://docs.conda.io/en/latest/miniconda.html) 下载适合您系统的安装程序
   - 运行安装程序，建议安装路径为：`D:\Developers\miniconda3` 或 `%USERPROFILE%\miniconda3`
   - 安装时选择"Add Miniconda3 to my PATH environment variable"（可选）
   - 完成安装后重启PowerShell

2. **安装Anaconda**（包含更多预装包）:
   - 访问 [Anaconda官网](https://www.anaconda.com/products/individual) 下载安装程序
   - 运行安装程序，建议安装路径为：`D:\Developers\anaconda3` 或 `%USERPROFILE%\anaconda3`
   - 安装时选择"Add Anaconda to my PATH environment variable"（可选）
   - 完成安装后重启PowerShell

3. **验证安装**:
   - 重启PowerShell后，您应该能看到Conda初始化信息
   - 运行 `conda --version` 确认安装成功

本配置文件会自动检测常见路径下的Conda安装，并进行初始化。如果您安装在自定义路径，可能需要修改配置文件中的`Get-CondaPath`函数。

## 使用指南

### 系统信息显示

启动PowerShell时，系统会自动显示系统信息表格。您也可以随时使用以下命令刷新系统信息：

```powershell
reload!
```

#### 配置系统信息显示

您可以控制是否在启动时显示系统信息表格：

```powershell
# 关闭系统信息显示
$global:ShowSystemInfoOnStartup = $false

# 开启系统信息显示
$global:ShowSystemInfoOnStartup = $true
```

您也可以使用以下命令快速切换系统信息显示状态：

```powershell
toggleinfo
```

当系统信息显示被关闭时，PowerShell提示符将只显示基本信息，如：
```
22:28:10 PS 7.5.0 losin@WINDOWS-HOME C:\Users\losin
$ 
```

这包括：
- 当前时间（22:28:10）
- PowerShell版本（PS 7.5.0）
- 用户名和主机名（losin@WINDOWS-HOME）
- 当前路径（C:\Users\losin）

关闭系统信息显示可以加快PowerShell启动速度，特别是在配置较低的系统上或当您不需要频繁查看系统详情时。

### 快速导航命令

| 命令 | 描述 |
|------|------|
| `proj` 或 `cdp` | 导航到项目目录并列出所有项目 |
| `proj ProjectName` | 导航到特定项目 |
| `docs` | 导航到文档目录 |
| `dl` | 导航到下载目录 |
| `desk` | 导航到桌面 |
| `home` | 导航到用户主目录 |
| `psdir` | 导航到PowerShell配置文件目录 |
| `navhelp` | 显示所有导航命令的帮助信息 |

示例：
```powershell
# 导航到项目目录
proj

# 导航到特定项目
proj MyProject

# 导航到下载目录
dl
```

### Conda环境管理

如果您已安装Conda，配置文件会自动检测并初始化它。以下是一些有用的Conda相关命令：

| 命令 | 描述 |
|------|------|
| `cenvs` | 列出所有可用的Conda环境 |
| `conda-create` | 创建新的Conda环境的便捷函数 |

创建新环境示例：
```powershell
# 创建基本Python环境
conda-create -Name myenv -PythonVersion 3.10

# 创建包含PyTorch的环境
conda-create -Name pytorch-env -WithTorch

# 创建包含TensorFlow和Jupyter的环境
conda-create -Name tf-jupyter -WithTensorflow -WithJupyter
```

#### 常用Conda命令

除了配置文件提供的便捷函数外，您还可以使用标准Conda命令：

```powershell
# 激活环境
conda activate 环境名称

# 停用当前环境
conda deactivate

# 安装包
conda install 包名称

# 更新包
conda update 包名称

# 删除环境
conda env remove -n 环境名称
```

## 自定义提示符

配置文件包含一个增强的PowerShell提示符，显示以下信息：
- 当前时间
- 活动的Conda环境（如果有）
- PowerShell版本
- 用户名和主机名
- 当前路径

## 系统要求

- PowerShell 5.1或更高版本
- Windows 10/11
- 可选：Miniconda或Anaconda（用于Conda相关功能）

## 故障排除

### 无法显示系统信息

如果系统信息无法正确显示，请确保您有足够的权限来访问系统信息。某些信息（如GPU详情）可能需要特定的硬件和驱动程序。

### Conda功能不工作

如果Conda相关功能不工作，请确保Conda已正确安装，并且可以在以下路径之一找到：
- `D:\Developers\miniconda3`
- `$env:USERPROFILE\miniconda3`
- `$env:USERPROFILE\anaconda3`
- `$env:LOCALAPPDATA\miniconda3`
- `$env:LOCALAPPDATA\anaconda3`
- `$env:PROGRAMFILES\miniconda3`
- `$env:PROGRAMFILES\anaconda3`

如果安装在其他路径，您需要修改配置文件中的`Get-CondaPath`函数，添加您的自定义路径。

### 快速导航命令不起作用

如果快速导航命令不起作用，请确保您已正确加载配置文件。您可以尝试重新加载配置文件：
```powershell
. $PROFILE
```

## 贡献

欢迎提交问题报告和改进建议！请随时提交Pull Request或创建Issue。

## 许可证

MIT
