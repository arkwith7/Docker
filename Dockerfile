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
    /opt/conda/bin/conda clean -tipy && \
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

