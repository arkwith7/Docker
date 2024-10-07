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

# 호스트의 보험기초서류 및 기타 문서를 마운트할 디렉토리 생성
RUN mkdir -p /workspace/host_docs

# 추출된 텍스트를 저장할 디렉토리 생성
RUN mkdir -p /workspace/extracted_texts

# 참조할 DRM 라이브러리 참조 디렉토리 생성
RUN mkdir -p /workspace/drm_library

# 로컬 파이썬 패키지 디렉토리 참조 위치 설정
ENV LOCAL_PACKAGES_DIR /local-packages

# 환경 변수를 위한 ARG 선언
ARG LLM_SERVICE_URL
ARG EMBEDDING_SERVICE_URL
ARG DOC_PARSER_SERVICE_URL
ARG UPSTAGE_API_KEY

# 환경 변수 설정
ENV LLM_SERVICE_URL=${LLM_SERVICE_URL}
ENV EMBEDDING_SERVICE_URL=${EMBEDDING_SERVICE_URL}
ENV DOC_PARSER_SERVICE_URL=${DOC_PARSER_SERVICE_URL}
ENV UPSTAGE_API_KEY=${UPSTAGE_API_KEY}

# 시작 스크립트 추가
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# 포트 노출
EXPOSE 18013

# 시작 스크립트 실행
CMD ["/usr/local/bin/start.sh"]

