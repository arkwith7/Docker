#!/bin/bash

# Bash 설정을 로드
source ~/.bashrc

# JupyterLab 설정 파일 수정
mkdir -p ~/.jupyter
cat << EOF > ~/.jupyter/jupyter_lab_config.py
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.allow_remote_access = True
c.LabApp.default_url = '/lab'

# 시작 시 터미널 자동 실행 설정
c.LabApp.terminals_enabled = True
c.TerminalManager.auto_open_terminal = True
EOF

# JupyterLab 실행 (토큰 없이)
jupyter lab --ip=0.0.0.0 --port=18013 --no-browser --allow-root --LabApp.answer_yes=True

# JupyterLab이 종료되면 bash 셸 시작
exec /bin/bash