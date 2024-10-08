#!/bin/bash

# Bash 설정을 로드
source ~/.bashrc

# JupyterLab 설정 파일 생성 또는 수정
jupyter lab --generate-config
echo "c.LabApp.default_url = '/lab?terminal=1'" >> ~/.jupyter/jupyter_lab_config.py

# JupyterLab 실행 (토큰 없이)
jupyter lab --ip=0.0.0.0 --port=18013 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''

# JupyterLab이 종료되면 bash 셸 시작
exec /bin/bash

