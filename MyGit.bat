@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Git 智能管理工具 v2.1
:: 作者: LaT-SKY
:: 修改日期: 2025-08-04
:: v0.2 更新: 还是不写了吧
:: ============================================================================


:: --- 主入口 ---
call :main_menu
exit /b


:: ============================================================================
:: 主菜单
:: ============================================================================
:main_menu
cls
echo *******************************************************
echo.
echo                  Git 智能工作流向导
echo.
echo *******************************************************
echo  [核心流程]
echo.
echo    1. 存盘并同步改动
echo    2. 获取团队最新代码
echo    3. 开始一个新任务
echo.
echo  [辅助功能]
echo.
echo    4. 查看我的工作进度
echo    5. 实用工具...
echo    6. 高级设定...
echo    7. 退出
echo.
echo *******************************************************

set /p "choice=请选择操作 (1-7): "

if "!choice!"=="1" call :save_and_sync
if "!choice!"=="2" call :get_latest_code
if "!choice!"=="3" call :initiate_pr
if "!choice!"=="3" call :start_new_task
if "!choice!"=="4" call :check_progress
if "!choice!"=="5" call :utility_menu
if "!choice!"=="6" call :advanced_menu
if "!choice!"=="7" exit /b

:: 如果输入无效，则提示并重新显示菜单
echo.
echo   请按任意键返回主菜单...
pause >nul
goto main_menu


:: ============================================================================
:: 核心功能模块
:: ============================================================================

:: --- 1. 存盘并同步改动 ---
:save_and_sync
cls
call :check_git_repo || goto :eof
echo ******** 存盘并同步改动 ********
echo.
echo 此功能会帮您将本地的所有改动“存盘”(commit) 并“同步”(push) 到远程仓库。
echo.

:: 获取当前分支名
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set "current_branch=%%i"
echo 当前分支: !current_branch!
echo.

:: 检查是否有变更
call :check_for_changes
if !has_changes! == 0 (
    echo 没有检测到新的文件变更。
    set /p "force_push=是否仍要尝试推送本地已有的提交? (Y/N): "
    if /i "!force_push!" neq "Y" goto :eof
    goto :push_changes
)

:: 添加并提交
set /p "commit_msg=请输入本次改动的简短描述: "
if not defined commit_msg (
    echo. & echo [错误] 描述信息不能为空！ & pause & goto :eof
)
echo.
echo 正在添加所有变更...
git add .
echo 正在提交...
git commit -m "!commit_msg!"
if !errorlevel! neq 0 (
    echo. & echo [错误] 提交失败，请检查上面的信息。 & pause & goto :eof
)

:push_changes
echo.
echo 正在将改动推送到远程仓库 (!current_branch! 分支)...
git push origin !current_branch!
if !errorlevel! neq 0 (
    echo.
    echo [提示] 推送失败。这可能是因为这是个新分支。
    set /p "setup_upstream=是否要将本地分支与远程关联并重试? (Y/N): "
    if /i "!setup_upstream!"=="Y" (
        git push --set-upstream origin !current_branch!
    )
)

echo.
echo 操作完成！
pause
goto :main_menu


:: --- 2. 获取团队最新代码 ---
:get_latest_code
cls
call :check_git_repo || goto :eof
echo ******** 获取团队最新代码 ********
echo.
echo 此功能将从远程主分支 (main/master) 拉取最新的代码，
echo 并尝试与您的当前分支合并，让您保持代码最新。
echo.
set /p "confirm=确认要拉取最新代码吗? (Y/N): "
if /i "!confirm!" neq "Y" goto :eof

echo.
echo 正在切换到主分支 (main) 并拉取更新...
git checkout main
git pull origin main
if !errorlevel! neq 0 (
    echo [提示] 切换或拉取 main 分支失败，尝试 master 分支...
    git checkout master
    git pull origin master
    if !errorlevel! neq 0 (
        echo [错误] 无法从 main 或 master 分支拉取更新。请手动检查。
        pause & goto :eof
    )
)

echo.
echo 更新已成功拉取！
pause
goto :main_menu

:: --- 3. 开始一个新任务 ---
:start_new_task
cls
call :check_git_repo || goto :eof
echo ******** 开始一个新任务 ********
echo.
echo 一个好的习惯是为每个新功能或修复创建一个独立的分支。
echo.
echo --- 现有分支列表 ---
git branch -a
echo ------------------------
echo.
set /p "branch_name=请输入新任务的分支名 (或输入已有分支名进行切换): "
if not defined branch_name (
    echo. & echo [错误] 分支名不能为空！ & pause & goto :eof
)

:: 检查分支是否已存在
git rev-parse --verify !branch_name! >nul 2>&1
if !errorlevel! == 0 (
    echo.
    echo 分支 "!branch_name!" 已存在，正在为您切换...
    git checkout !branch_name!
) else (
    echo.
    echo 正在为您创建并切换到新分支 "!branch_name!"...
    git checkout -b !branch_name!
)

if !errorlevel! neq 0 (
    echo. & echo [错误] 操作失败，请检查输入或Git状态。
) else (
    echo. & echo 操作成功！您现在位于 "!branch_name!" 分支。
)
pause
goto :main_menu


:: --- 5. 查看我的工作进度 ---
:check_progress
cls
call :check_git_repo || goto :eof
echo ******** 查看我的工作进度 ********
echo.
echo --- 1. 文件状态---
git status
echo.
echo --------------------------------------------------
echo.
echo --- 2. 最近提交历史 ---
git log --oneline -10 --graph --decorate
echo.
echo --------------------------------------------------
pause
goto :main_menu


:: ============================================================================
:: 实用工具菜单
:: ============================================================================
:utility_menu
cls
echo ****************************************
echo.
echo                 实用工具
echo.
echo ****************************************
echo  1. 撤销上一次提交
echo  2. 暂存工作进度
echo  3. 清理本地已合并分支
echo  4. 生成 .gitignore 文件
echo  5. 返回主菜单
echo ****************************************

set /p "util_choice=请选择 (1-5): "
if "!util_choice!"=="1" call :undo_last_commit
if "!util_choice!"=="2" call :stash_menu
if "!util_choice!"=="3" call :clean_local_branches
if "!util_choice!"=="4" call :generate_gitignore_menu
if "!util_choice!"=="5" goto main_menu

goto utility_menu

:: --- 实用工具子模块 ---

:undo_last_commit
call :check_git_repo || goto :eof
echo.
echo --- 撤销上一次提交 ---
echo 此操作会将最近一次的提交撤销，但保留所有文件改动在工作区。
echo.
set /p "confirm=您确定要这样做吗? (Y/N): "
if /i not "!confirm!"=="Y" goto :eof

echo 正在执行 git reset --soft HEAD~1 ...
git reset --soft HEAD~1
echo.
echo 操作完成！上一次提交已被撤销，相关文件改动已放回暂存区。
echo 您可以修改后重新提交。
pause
goto :main_menu

:stash_menu
cls
echo ******** 暂存工作进度********
echo.
git stash list
echo ------------------------------------
echo 1. 暂存当前所有改动
echo 2. 恢复最近一次暂存
echo 3. 返回
echo ************************************
set /p "stash_choice=请选择 (1-3): "
if "!stash_choice!"=="1" (
    echo 正在暂存... & git stash & echo 操作完成！
    pause
)
if "!stash_choice!"=="2" (
    echo 正在恢复... & git stash pop & echo 操作完成！
    pause
)
if "!stash_choice!"=="3" goto :eof
goto stash_menu

:clean_local_branches
call :check_git_repo || goto :eof
echo.
echo --- 清理本地已合并分支 ---
echo 此功能会查找已经合并到 main/master 分支的本地分支，并让您选择删除。
echo.
echo 正在查找可清理的分支...
:: 使用 findstr 替代 grep
for /f "tokens=*" %%b in ('git branch --merged main ^| findstr /v /c:"* main"') do (
    set /p "del_confirm=是否删除已合并的本地分支 "%%b"? (Y/N): "
    if /i "!del_confirm!"=="Y" (
        git branch -d %%b
    )
)
for /f "tokens=*" %%b in ('git branch --merged master ^| findstr /v /c:"* master"') do (
    set /p "del_confirm=是否删除已合并的本地分支 "%%b"? (Y/N): "
    if /i "!del_confirm!"=="Y" (
        git branch -d %%b
    )
)
echo.
echo 清理完成！
pause
goto :main_menu

:generate_gitignore_menu
cls
echo ******** 生成 .gitignore 文件 ********
echo 1. 通用类型
echo 2. C++ (Visual Studio)
echo 3. Python
echo 4. Node.js
echo 5. 返回
echo ************************************
set /p "gitchoice=请选择项目类型: "
set "gittemplate="
if "!gitchoice!"=="1" set "gittemplate=General"
if "!gitchoice!"=="2" set "gittemplate=C++"
if "!gitchoice!"=="3" set "gittemplate=Python"
if "!gitchoice!"=="4" set "gittemplate=NodeJS"
if "!gitchoice!"=="5" goto :eof

if defined gittemplate (
    call :write_gitignore !gittemplate!
    echo .gitignore 文件已根据 !gittemplate! 模板生成/覆盖！
) else (
    echo 无效输入！
)
pause
goto :main_menu


:: ============================================================================
:: 高级设定菜单
:: ============================================================================
:advanced_menu
cls
echo ****************************************
echo.
echo                 高级设定
echo.
echo ****************************************
echo  1. 创建标签
echo  2. 合并分支
echo  3. 删除分支
echo  4. 远程仓库管理
echo  5. 本地仓库初始化
echo  6. 配置用户信息
echo  7. 返回主菜单
echo ****************************************

set /p "adv_choice=请选择 (1-7): "

if "!adv_choice!"=="1" call :create_tag
if "!adv_choice!"=="2" call :merge_branch
if "!adv_choice!"=="3" call :delete_branch
if "!adv_choice!"=="4" call :remote_menu
if "!adv_choice!"=="5" call :init_repo
if "!adv_choice!"=="6" call :config_user
if "!adv_choice!"=="7" goto main_menu

goto advanced_menu

:: --- 高级设定子模块 ---
:create_tag
call :check_git_repo || goto :eof
echo.
echo --- 创建并推送标签 ---
set /p "tag_name=请输入标签名: "
if not defined tag_name ( echo [错误] 标签名不能为空。 & pause & goto :eof)
set /p "tag_msg=请输入标签的附注信息 (可留空): "

if defined tag_msg (
    git tag -a "!tag_name!" -m "!tag_msg!"
) else (
    git tag "!tag_name!"
)
echo.
echo 标签 "!tag_name!" 已在本地创建。
set /p "push_tag=是否要将此标签推送到远程仓库? (Y/N): "
if /i "!push_tag!"=="Y" (
    git push origin !tag_name!
)
echo 操作完成！
pause
goto advanced_menu

:merge_branch
call :check_git_repo || goto :eof
echo.
echo --- 合并分支 ---
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD') do set "current_branch=%%i"
echo 当前所在分支: !current_branch!
echo.
git branch -a
echo.
set /p "source_branch=请输入要合并到 "!current_branch!" 的分支名: "
if not defined source_branch (
    echo [错误] 分支名不能为空。 & pause & goto :eof
)
git merge !source_branch!
if !errorlevel! neq 0 (
    echo [警告] 合并时出现冲突！请手动解决冲突后再次提交。
) else (
    echo 合并成功！
)
pause
goto advanced_menu

:delete_branch
call :check_git_repo || goto :eof
echo.
echo --- 删除分支 ---
git branch -a
echo.
set /p "del_branch=请输入要删除的本地分支名: "
if not defined del_branch (
    echo [错误] 分支名不能为空。 & pause & goto :eof
)
git branch -d !del_branch!
if !errorlevel! neq 0 (
    echo [错误] 删除失败。分支可能未完全合并，可使用 -D 强制删除。
) else (
    echo 分支 "!del_branch!" 已删除。
)
pause
goto advanced_menu

:remote_menu
cls
echo ******** 远程仓库管理 ********
echo 1. 查看远程仓库
echo 2. 添加远程仓库
echo 3. 修改远程URL
echo 4. 返回
echo ********************************
set /p "remote_choice=请选择 (1-4): "
if "!remote_choice!"=="1" (git remote -v & pause)
if "!remote_choice!"=="2" call :add_remote
if "!remote_choice!"=="3" call :change_remote_url
if "!remote_choice!"=="4" goto :eof
goto remote_menu

:add_remote
set /p "remote_name=请输入远程名称 (如origin): "
set /p "remote_url=请输入远程URL: "
git remote add !remote_name! !remote_url!
echo 远程仓库已添加！ & pause
goto :main_menu

:change_remote_url
git remote -v
set /p "remote_name=请输入要修改的远程名称: "
set /p "new_url=请输入新URL: "
git remote set-url !remote_name! !new_url!
echo 远程URL已更新！ & pause
goto :eof

:init_repo
if exist ".git" (
    echo 当前目录已是一个Git仓库。
) else (
    git init
    echo 新的Git仓库已初始化！
)
pause
goto :main_menu

:config_user
echo.
echo --- 当前用户信息 ---
git config user.name
git config user.email
echo --------------------
echo.
set /p "username=请输入新的全局用户名 (留空跳过): "
if not "!username!"=="" git config --global user.name "!username!"
set /p "email=请输入新的全局邮箱 (留空跳过): "
if not "!email!"=="" git config --global user.email "!email!"
echo.
echo 用户信息已更新！
pause
goto :main_menu


:: ============================================================================
:: 辅助函数 (Helper Functions)
:: ============================================================================

:: --- 检查当前目录是否为Git仓库 ---
:check_git_repo
git rev-parse --is-inside-work-tree >nul 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [错误] 当前目录不是一个有效的 Git 仓库！
    echo 请先进入一个Git仓库目录，或使用“高级设定”中的“初始化”来创建一个新仓库。
    echo.
    pause
    exit /b 1
)
exit /b 0

:: --- 检查是否有未提交的变更 ---
:check_for_changes
set "has_changes=0"
git diff --quiet --exit-code || set "has_changes=1"
git diff --cached --quiet --exit-code || set "has_changes=1"
git ls-files --others --exclude-standard | findstr . >nul 2>&1
if !errorlevel! == 0 set "has_changes=1"
exit /b

:: --- 根据模板写入 .gitignore ---
:write_gitignore
(
    if /i "%1"=="General" (
        echo # General
        echo .DS_Store
        echo Thumbs.db
        echo *.log
        echo *.tmp
    )
    if /i "%1"=="C++" (
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
        echo *.pdb
        echo *.ilk
        echo *.obj
        echo *.exe
        echo *.dll
        echo *.lib
        echo *.slo
        echo *.o
    )
    if /i "%1"=="Python" (
        echo # Python
        echo __pycache__/
        echo *.pyc
        echo *.pyo
        echo *.pyd
        echo .Python
        echo env/
        echo venv/
        echo .env
        echo .venv
        echo *.egg-info/
        echo .pytest_cache/
    )
    if /i "%1"=="NodeJS" (
        echo # Node.js
        echo node_modules/
        echo npm-debug.log*
        echo yarn-debug.log*
        echo yarn-error.log*
        echo .npm
        echo .yarn
        echo pnpm-lock.yaml
        echo dist/
        echo build/
    )
) > .gitignore
exit /b

