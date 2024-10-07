Dockerfile

# 우분투 최신 버전 사용
FROM ubuntu:latest

# 시스템 업데이트 및 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 미니콘다 설치
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

# PATH에 conda 추가
ENV PATH=$CONDA_DIR/bin:$PATH

# 콘다 최신 버전으로 업데이트
RUN conda update -n base -c defaults conda

# 파이썬 최신 버전 설치
RUN conda install python=3.11

# JupyterLab 및 필요한 패키지 설치
RUN conda install -c conda-forge jupyterlab requests

# 작업 디렉토리 설정
WORKDIR /workspace

# 로컬 패키지 디렉토리 참조 위치 설정
ENV LOCAL_PACKAGES_DIR /local-packages

# API 서비스 호스트 설정
ENV LLM_SERVICE_URL=https://api.upstage.ai/v1/solar
ENV EMBEDDING_SERVICE_URL=https://api.upstage.ai/v1/solar
ENV DOC_PARSER_SERVICE_URL=https://api.upstage.ai/v1/document-ai/document-parse
ENV UPSTAGE_API_KEY=up_xHRxAmCZHbKDbQT0uiBO3VrfJXYxk

# 시작 스크립트 추가
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# 포트 노출
EXPOSE 18013

# 시작 스크립트 실행
CMD ["/usr/local/bin/start.sh"]


그리고 start.sh 스크립트를 다음과 같이 작성합니다:
#!/bin/bash

# Jupyter Lab 시작
jupyter lab --ip=0.0.0.0 --port=18013 --no-browser --allow-root &

# 터미널 세션 시작 (여기서는 bash를 사용)
/bin/bash


이제 도커 이미지를 빌드하고 실행합니다:
# 이미지 빌드
docker build -t ubuntu-miniconda-jupyterlab-terminal .

# 환경변수를 사용하여 이미지 빌드
docker build --build-arg LLM_SERVICE_URL=$(grep LLM_SERVICE_URL .env | cut -d '=' -f2) \
             --build-arg EMBEDDING_SERVICE_URL=$(grep EMBEDDING_SERVICE_URL .env | cut -d '=' -f2) \
             --build-arg DOC_PARSER_SERVICE_URL=$(grep DOC_PARSER_SERVICE_URL .env | cut -d '=' -f2) \
             --build-arg UPSTAGE_API_KEY=$(grep UPSTAGE_API_KEY .env | cut -d '=' -f2) \
             -t ubuntu-miniconda-jupyterlab-terminal .


이제 이 이미지를 빌드하고 실행할 때, 다음과 같이 도커 네트워크를 사용하여 다른 서비스들과 연결해야 합니다:

1. 먼저 도커 네트워크를 생성합니다:
docker network create my_api_network

2. 기존의 API 서비스 컨테이너들을 이 네트워크에 연결합니다:
docker network connect my_api_network llm_service
docker network connect my_api_network embadding_service
docker network connect my_api_network doc_parser_service

3. 주피터랩 컨테이너를 실행할 때 이 네트워크에 연결합니다:
# 컨테이너 실행
docker run -it -p 18013:18013 \
    -v $(pwd):/workspace \
    -v /home/samuel/local-python-package:/local-packages:ro \
    --network my_api_network \
    --name jupyterlab_terminal_container \
    ubuntu-miniconda-jupyterlab-terminal

# 환경정보를 사용하여 컨테이너 실행
docker run --env-file .env -d -p 18013:18013 \
    -v $(pwd):/workspace \
    -v /home/samuel/local-python-package:/local-packages:ro \
    -v /mnt/c/Rbrain/PJT/workspace/docs:/workspace/host_docs \
    -v /mnt/c/Rbrain/PJT/workspace/extracted_texts:/workspace/extracted_texts \
    ubuntu-miniconda-jupyterlab-terminal

이 설정의 주요 특징은 다음과 같습니다:
1. JupyterLab과 터미널 세션이 모두 실행됩니다.
2. 호스트의 '/home/arkwith/local-python-package' 디렉토리가 컨테이너 내부의 '/local-packages' 디렉토리로 읽기 전용으로 마운트됩니다.
3. 사용자는 터미널에서 직접 pip install --no-index --find-links=/local-packages <package_name> 명령을 사용하여 패키지를 설치할 수 있습니다.
컨테이너 내부의 터미널에서 패키지를 설치하려면 다음과 같이 할 수 있습니다:
pip install --no-index --find-links=/local-packages <package_name>
	
이렇게 설정하면 주피터랩 컨테이너 내에서 다른 API 서비스들에 접근할 수 있습니다. 파이썬 코드에서는 다음과 같이 환경 변수를 사용하여 API에 접근할 수 있습니다:

import os
import requests

llm_url = os.environ['LLM_SERVICE_URL']
embedding_url = os.environ['EMBEDDING_SERVICE_URL']
doc_parser_url = os.environ['DOC_PARSER_SERVICE_URL']

# LLM 서비스 사용 예
response = requests.get(f"{llm_url}/some_endpoint")

# Embedding 서비스 사용 예
response = requests.get(f"{embedding_url}/some_endpoint")

# Doc Parser 서비스 사용 예
response = requests.get(f"{doc_parser_url}/some_endpoint")
	