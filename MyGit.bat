@echo off

setlocal enabledelayedexpansion

:: 主函数
call :main_menu

exit /b

:: ========== 主菜单 ==========
:main_menu
cls
echo ****************************************
echo          Git 智能管理工具
echo ****************************************
echo 1. 代码提交与推送
echo 2. 远程操作
echo 3. 分支管理
echo 4. 仓库设置
echo 5. 退出
echo ****************************************

set /p "choice=请选择操作 (1-5): "

if "!choice!"=="1" (
    call :commit_menu
) else if "!choice!"=="2" (
    call :remote_menu
) else if "!choice!"=="3" (
    call :branch_menu
) else if "!choice!"=="4" (
    call :config_menu
) else if "!choice!"=="5" (
    exit /b
) else (
    echo 无效输入，请重新选择！
    pause
    goto main_menu
)
goto main_menu

:: ========== 二级菜单：代码提交与推送 ==========
:commit_menu
cls
echo ******** 代码提交与推送 ********
echo 1. 提交并推送所有变更
echo 2. 仅提交变更
echo 3. 仅推送变更
echo 4. 查看当前状态
echo 5. 返回主菜单
echo ********************************

set /p "commit_choice=请选择 (1-5): "

if "!commit_choice!"=="1" (
    call :commit_and_push
    goto commit_menu
) else if "!commit_choice!"=="2" (
    call :commit_only
    goto commit_menu
) else if "!commit_choice!"=="3" (
    call :push_only
    goto commit_menu
) else if "!commit_choice!"=="4" (
    call :show_status
    goto commit_menu
) else if "!commit_choice!"=="5" (
    goto main_menu
) else (
    echo 无效输入！
    pause
    goto commit_menu
)

:: ========== 二级菜单：远程操作 ==========
:remote_menu
cls
echo ******** 远程操作 ********
echo 1. 拉取远程更新
echo 2. 查看远程仓库
echo 3. 添加远程仓库
echo 4. 修改远程URL
echo 5. 返回主菜单
echo ********************************

set /p "remote_choice=请选择 (1-5): "

if "!remote_choice!"=="1" (
    call :pull_from_remote
    goto remote_menu
) else if "!remote_choice!"=="2" (
    git remote -v
    pause
    goto remote_menu
) else if "!remote_choice!"=="3" (
    call :add_remote
    goto remote_menu
) else if "!remote_choice!"=="4" (
    call :change_remote_url
    goto remote_menu
) else if "!remote_choice!"=="5" (
    goto main_menu
) else (
    echo 无效输入！
    pause
    goto remote_menu
)

:: ========== 二级菜单：分支管理 ==========
:branch_menu
cls
echo ******** 分支管理 ********
echo 1. 创建新分支
echo 2. 切换分支
echo 3. 合并分支
echo 4. 删除分支
echo 5. 查看所有分支
echo 6. 返回主菜单
echo ********************************

set /p "branch_choice=请选择 (1-6): "

if "!branch_choice!"=="1" (
    call :create_branch
    goto branch_menu
) else if "!branch_choice!"=="2" (
    call :switch_branch
    goto branch_menu
) else if "!branch_choice!"=="3" (
    call :merge_branch
    goto branch_menu
) else if "!branch_choice!"=="4" (
    call :delete_branch
    goto branch_menu
) else if "!branch_choice!"=="5" (
    git branch -a
    pause
    goto branch_menu
) else if "!branch_choice!"=="6" (
    goto main_menu
) else (
    echo 无效输入！
    pause
    goto branch_menu
)

:: ========== 二级菜单：仓库设置 ==========
:config_menu
cls
echo ******** 仓库设置 ********
echo 1. 生成.gitignore
echo 2. 配置用户信息
echo 3. 初始化新仓库
echo 4. 返回主菜单
echo ********************************

set /p "config_choice=请选择 (1-4): "

if "!config_choice!"=="1" (
    call :generate_gitignore
    goto config_menu
) else if "!config_choice!"=="2" (
    call :config_user
    goto config_menu
) else if "!config_choice!"=="3" (
    call :init_repo
    goto config_menu
) else if "!config_choice!"=="4" (
    goto main_menu
) else (
    echo 无效输入！
    pause
    goto config_menu
)

:: ========== 功能函数 ==========
:commit_and_push
call :check_git_repo || goto :eof

git status -s

set "has_changes=0"
git diff --quiet --exit-code || set "has_changes=1"
git diff --cached --quiet --exit-code || set "has_changes=1"

:: 检查是否有未被跟踪的文件
git ls-files --others --exclude-standard >nul 2>&1
if !errorlevel! == 0 (
    echo 检测到新文件未被跟踪，正在添加...
    git add .  
)

:: 确认是否有变更
if !has_changes!==0 (
    echo 没有检测到文件变更
    goto push_part
)

call :check_gitignore

set /p "commit_msg=请输入提交信息: "
if "!commit_msg!"=="" (
    echo 提交信息不能为空！
    pause
    goto :eof
)

echo 正在提交变更...
git add . 
git status -s  :: 显示暂存区状态，检查文件是否成功加入
git commit -m "!commit_msg!"
if errorlevel 1 (
    echo 提交失败！
    pause
    goto :eof
)

:push_part
echo 正在推送变更...
git push origin main
if errorlevel 1 (
    echo 推送失败！
    call :handle_push_error
)
echo 操作完成！
pause
goto :eof

:commit_only
call :check_git_repo || goto :eof

set /p "commit_msg=请输入提交信息: "
if "!commit_msg!"=="" (
    echo 提交信息不能为空！
    pause
    goto :eof
)

git add . 
git commit -m "!commit_msg!"
echo 提交完成！
pause
goto :eof

:push_only
call :check_git_repo || goto :eof
git push origin main
if errorlevel 1 (
    echo 推送失败！
    call :handle_push_error
) else (
    echo 推送成功！
)
pause
goto :eof

:pull_from_remote
call :check_git_repo || goto :eof
set /p "branch=请输入要拉取的分支名 (默认:main): "
if "!branch!"=="" set "branch=main"
git pull origin !branch!
echo 拉取完成！
pause
goto :eof

:add_remote
call :check_git_repo || goto :eof
set /p "remote_name=请输入远程名称 (如origin): "
set /p "remote_url=请输入远程URL: "
git remote add !remote_name! !remote_url!
echo 远程仓库已添加！
pause
goto :eof

:change_remote_url
call :check_git_repo || goto :eof
git remote -v
set /p "remote_name=请输入要修改的远程名称: "
set /p "new_url=请输入新URL: "
git remote set-url !remote_name! !new_url!
echo 远程URL已更新！
pause
goto :eof

:create_branch
call :check_git_repo || goto :eof
set /p "new_branch=请输入新分支名: "
git branch !new_branch!
echo 分支创建成功！
pause
goto :eof

:switch_branch
call :check_git_repo || goto :eof
set /p "target_branch=请输入要切换的分支名: "
git checkout !target_branch!
echo 分支切换成功！
pause
goto :eof

:merge_branch
call :check_git_repo || goto :eof
echo 当前分支: & git branch --show-current
git branch -a
set /p "source_branch=请输入要合并的分支名: "
git merge !source_branch!
if errorlevel 1 (
    echo 合并冲突！请手动解决后提交
) else (
    echo 合并成功！
)
pause
goto :eof

:delete_branch
call :check_git_repo || goto :eof
git branch
set /p "del_branch=请输入要删除的分支名: "
git branch -d !del_branch!
echo 分支删除成功！
pause
goto :eof

:generate_gitignore
call :check_gitignore
echo .gitignore 已生成/更新
pause
goto :eof

:config_user
git config --global user.name
git config --global user.email
echo.
set /p "username=请输入新的用户名 (留空跳过): "
if not "!username!"=="" (
    git config --global user.name "!username!"
)
set /p "email=请输入新的邮箱 (留空跳过): "
if not "!email!"=="" (
    git config --global user.email "!email!"
)
echo 用户信息已更新！
pause
goto :eof

:init_repo
git init
echo 新的Git仓库已初始化！
pause
goto :eof

:show_status
call :check_git_repo || goto :eof
git status
echo.
echo 最近5次提交:
git log --oneline -5
pause
goto :eof

:check_gitignore
if not exist ".gitignore" (
    echo 生成 .gitignore 文件...
    (
        echo # Prerequisites
        echo *.d
        echo # Compiled Object files
        echo *.slo
        echo *.lo
        echo *.o
        echo *.obj
        echo # Precompiled Headers
        echo *.gch
        echo *.pch
        echo # Linker files
        echo *.ilk
        echo # Debugger Files
        echo *.pdb
        echo # Compiled Dynamic libraries
        echo *.so
        echo *.dylib
        echo *.dll
        echo # Fortran module files
        echo *.mod
        echo *.smod
        echo # Compiled Static libraries
        echo *.lai
        echo *.la
        echo *.a
        echo *.lib
        echo # Executables
        echo *.exe
        echo *.out
        echo *.app
        echo # debug information files
        echo *.dwo
        echo # Visual Studio
        echo .vs/
        echo x64/
        echo Debug/
        echo Release/
        echo *.suo
        echo *.user
        echo *.vcxproj.user
        echo *.db
        echo *.ipch
        echo *.log
        echo bin/
        echo obj/
        echo #vcpkg
        echo vcpkg/
    ) > .gitignore
)
exit /b

:check_git_repo
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo 错误：当前目录不是 Git 仓库！
    pause
    exit /b 1
)
exit /b 0

:handle_push_error
set /p "remote_url=检测到推送问题，请输入远程仓库URL (留空取消): "
if not "!remote_url!"=="" (
    git remote set-url origin "!remote_url!"
    git push -u origin main
)
exit /b
