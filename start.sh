#!/bin/bash

# Jupyter Lab 시작
jupyter lab --ip=0.0.0.0 --port=18013 --no-browser --allow-root &

# 터미널 세션 시작 (여기서는 bash를 사용)
/bin/bash