# PowerShell 增强配置文件

这个PowerShell配置文件提供了一系列实用功能，包括快速导航、Conda环境管理等，旨在提升您的PowerShell使用体验。

## 功能概览

- **美化终端**：使用Oh-My-Posh提供美观的命令行提示符
- **快速导航**：一系列命令用于快速导航到常用目录
- **Conda环境管理**：自动检测并初始化Conda环境（如果已安装）
- **Python和Conda信息**：提供命令查看Python和Conda环境详细信息
- **语法高亮和命令预测**：通过PSReadLine增强命令行编辑体验
- **文件图标**：使用Terminal-Icons为文件和文件夹添加直观图标
- **Git集成**：通过posh-git提供Git仓库状态显示和命令补全

## 安装指南

1. 将此仓库克隆到您的计算机上：
   ```powershell
   git clone https://github.com/yourusername/profiles-info.git
   ```

2. 安装必要的PowerShell模块：
   ```powershell
   # 安装Oh-My-Posh（美化提示符）
   winget install JanDeDobbeleer.OhMyPosh -s winget
   
   # 设置Oh-My-Posh环境变量（重要）
   [Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", "$env:LOCALAPPDATA\Programs\oh-my-posh\themes", "User")
   # 重新加载环境变量
   $env:POSH_THEMES_PATH = [Environment]::GetEnvironmentVariable("POSH_THEMES_PATH", "User")

   # 安装必要的PowerShell模块
   Install-Module posh-git -Scope CurrentUser -Force
   Install-Module PSReadLine -Scope CurrentUser -Force
   Install-Module Terminal-Icons -Scope CurrentUser -Force
   ```

3. 安装 Nerd Fonts 字体（Oh-My-Posh 图标显示需要）：
   ```powershell
   # 使用 Oh-My-Posh 安装 Nerd Fonts
   oh-my-posh font install
   
   # 或者手动下载安装（推荐 Cascadia Code 或 FiraCode）
   # 从 https://www.nerdfonts.com/font-downloads 下载
   ```
   安装字体后，请在终端设置中选择带有 "NF" 或 "Nerd Font" 后缀的字体。

4. 将配置文件链接到您的PowerShell配置文件位置：
   ```powershell
   # 查看您的PowerShell配置文件路径
   echo $PROFILE
   
   # 创建符号链接（管理员权限）
   New-Item -ItemType SymbolicLink -Path $PROFILE -Target "路径\到\profiles-info\profile.ps1" -Force
   ```

5. 重启PowerShell或重新加载配置文件：
   ```powershell
   . $PROFILE
   ```

### 模块说明

本配置文件使用了以下PowerShell模块来增强体验：

1. **Oh-My-Posh**：
   - 用途：提供美观的命令行提示符
   - 功能：显示时间、路径、Git状态等信息
   - 文档：[Oh-My-Posh官方文档](https://ohmyposh.dev/)
   - 环境变量：`POSH_THEMES_PATH` 指向主题文件夹
   - 主题文件：本配置使用 `1_shell.omp.json` 主题
   - 自定义：可以通过修改配置文件中的主题路径来更换主题
     ```powershell
     # 查看可用主题
     Get-ChildItem $env:POSH_THEMES_PATH

     # 在配置文件中更改主题（示例）
     oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/atomic.omp.json" | Invoke-Expression
     ```

2. **posh-git**：
   - 用途：提供Git集成
   - 功能：在提示符中显示Git仓库状态，提供Git命令补全
   - 文档：[posh-git GitHub页面](https://github.com/dahlbyk/posh-git)

3. **PSReadLine**：
   - 用途：增强PowerShell命令行编辑体验
   - 功能：语法高亮、命令历史搜索、智能补全
   - 文档：[PSReadLine文档](https://learn.microsoft.com/en-us/powershell/module/psreadline/)

4. **Terminal-Icons**：
   - 用途：为文件和文件夹添加图标
   - 功能：在使用`Get-ChildItem`或`ls`命令时显示文件类型图标
   - 文档：[Terminal-Icons GitHub页面](https://github.com/devblackops/Terminal-Icons)

### Terminal-Icons 使用

Terminal-Icons模块为文件和文件夹添加了直观的图标，使文件浏览更加直观：

```powershell
# 查看带图标的文件列表
Get-ChildItem
# 或使用别名
ls
```

您会看到不同类型的文件和文件夹前面会显示对应的图标，例如：
- 文件夹
- 文本文件
- Python文件
- Excel文件
等等

这使得在终端中浏览文件时能够更快地识别文件类型。

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

### Oh-My-Posh 配置

本配置文件使用 Oh-My-Posh 来美化 PowerShell 提示符，默认使用 `1_shell.omp.json` 主题：

```powershell
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/1_shell.omp.json" | Invoke-Expression
```

#### 自定义 Oh-My-Posh 主题

您可以轻松更换 Oh-My-Posh 主题：

1. **查看可用主题**：
   ```powershell
   Get-ChildItem $env:POSH_THEMES_PATH
   ```

2. **预览主题**：
   ```powershell
   oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/主题名称.omp.json" | Invoke-Expression
   ```

3. **永久更改主题**：
   编辑 `profile.ps1` 文件，修改第一行中的主题路径：
   ```powershell
   oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/您喜欢的主题.omp.json" | Invoke-Expression
   ```

4. **自定义主题**：
   您还可以创建自己的主题文件：
   ```powershell
   # 复制现有主题作为起点
   Copy-Item "$env:POSH_THEMES_PATH/1_shell.omp.json" -Destination "~/custom_theme.omp.json"
   
   # 编辑自定义主题
   notepad ~/custom_theme.omp.json
   
   # 使用自定义主题
   oh-my-posh init pwsh --config "~/custom_theme.omp.json" | Invoke-Expression
   ```

#### 常见问题解决

如果 Oh-My-Posh 图标显示不正确，请确保您使用的是支持 Nerd Fonts 的终端字体，如 Cascadia Code PL、FiraCode NF 等。

### PSReadLine 配置

本配置文件包含了一些PSReadLine的增强设置，使您的PowerShell体验更加流畅：

```powershell
# PSReadLine 配置
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{
    Command            = 'Magenta'
    Parameter          = 'DarkGreen'
    InlinePrediction   = 'DarkGray'
}
```

这些设置提供了以下功能：

1. **命令预测**：基于您的命令历史提供智能建议
   - 当您开始输入命令时，会看到灰色的预测文本
   - 按下 `→` 键或 `Ctrl+F` 接受建议

2. **语法高亮**：
   - 命令显示为洋红色
   - 参数显示为深绿色
   - 预测文本显示为深灰色

3. **常用快捷键**：
   - `Ctrl+Space`：显示可能的补全
   - `Ctrl+r`：搜索命令历史
   - `Ctrl+→`：向右移动一个单词
   - `Ctrl+←`：向左移动一个单词
   - `Ctrl+Backspace`：删除光标前的单词

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
| `condainfo` | 显示Conda版本和环境信息 |
| `condaenv` | 激活指定的Conda环境 |
| `pyinfo` | 显示Python版本和已安装包信息 |
| `devenv` | 显示完整的Python和Conda开发环境信息 |

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

### Python和Conda显示

您可以使用以下命令来管理Python和Conda信息的显示：

```powershell
# 显示Python信息
pyinfo

# 显示Conda信息
condainfo

# 显示完整的开发环境信息
devenv
```

这些命令可以帮助您快速了解当前的Python和Conda环境状态，特别是在处理多个项目和环境时非常有用。

**注意**：当您激活Conda环境时，Conda会自动在PowerShell提示符中显示当前环境名称，无需额外配置。例如：

```
(base) PS C:\Users\username>
```

或者激活其他环境后：

```
(myenv) PS C:\Users\username>
```

## 系统要求

- PowerShell 5.1或更高版本
- Windows 10/11
- 可选：Miniconda或Anaconda（用于Conda相关功能）

## 故障排除

### Conda功能不工作

如果Conda相关功能不工作，请确保Conda已正确安装，并且可以在以下路径之一找到：
- `D:\Developers\miniconda3`
- `$env:USERPROFILE\miniconda3`
- `$env:USERPROFILE\anaconda3`
- `C:\ProgramData\Anaconda3`
- `C:\ProgramData\miniconda3`

如果安装在其他路径，您需要修改配置文件中的`Initialize-CondaEnvironment`函数，添加您的自定义路径。

## 贡献

欢迎提交问题报告和改进建议！请随时提交Pull Request或创建Issue。

## 许可证

MIT
