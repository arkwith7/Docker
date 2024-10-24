# 우분투 최신 버전 사용
FROM ubuntu:latest

# 시간대 설정을 위한 ARG 선언 (기본값: Asia/Seoul)
ARG TZ=Asia/Seoul

# 시스템 업데이트 및 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    curl \
    tzdata \
    bash-completion \
    openjdk-11-jdk \
    git \
    zip \
    unzip \
    vim \
    nano \
    libsqlite3-dev \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Python 3.11 저장소 추가 및 설치
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-venv python3.11-dev && \
    rm -rf /var/lib/apt/lists/*

# Python 3.11을 기본 Python으로 설정
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --set python3 /usr/bin/python3.11

# pip 설치
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# 시간대 설정
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Java 환경 변수 설정
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Python 가상환경 생성 및 활성화
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# pip 업그레이드 및 필요한 파이썬 패키지 설치
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    jupyterlab \
    requests \
    beautifulsoup4 \
    xlwings \
    openpyxl \
    jpype1 \
    openai \
    pandas \
    numpy \
    matplotlib \
    seaborn \
    scikit-learn \
    llama-index-readers-file \
    pdfminer.six \
    PyPDF2 \
    PyMuPDF \
    pdfplumber \
    tabula-py \
    python-dotenv \
    langchain-community \
    langchain-experimental \
    langchain-core \
    langchain-openai \
    langsmith \
    langchainhub \
    langchain-upstage \
    langchain_chroma \
    llama-index-readers-file \
    langchain-teddynote \   
    faiss-cpu \
    chromadb \
    pgvector \
    psycopg2-binary \
    rank_bm25 \
    kiwipiepy \
    konlpy \
    ipython \
    ipdb \
    flake8 \
    black \
    pydantic \
    fastapi \
    uvicorn \
    pydantic-settings

# SQLite3 모듈 테스트
RUN python -c "import sqlite3; print(sqlite3.sqlite_version)"

# JupyterLab 설정 파일 생성
RUN mkdir -p /root/.jupyter && \
    echo "c.ServerApp.token = ''" > /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.password = ''" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.ServerApp.allow_remote_access = True" >> /root/.jupyter/jupyter_lab_config.py && \
    echo "c.LabApp.terminals_enabled = True" >> /root/.jupyter/jupyter_lab_config.py


# 작업 디렉토리 설정
WORKDIR /workspace

# 호스트의 보험기초서류 및 기타 문서를 마운트할 디렉토리 생성
RUN mkdir -p /workspace/host_docs

# 추출된 텍스트를 저장할 디렉토리 생성
RUN mkdir -p /workspace/extracted_texts

# 참조할 DRM 라이브러리 참조 디렉토리 생성
RUN mkdir -p /workspace/softcamp

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

# Bash 설정 파일 생성
RUN echo "source /etc/profile.d/bash_completion.sh" >> ~/.bashrc && \
    echo "set completion-ignore-case On" >> ~/.inputrc && \
    echo "set show-all-if-ambiguous On" >> ~/.inputrc && \
    echo "\"\e[A\": history-search-backward" >> ~/.inputrc && \
    echo "\"\e[B\": history-search-forward" >> ~/.inputrc && \
    echo "alias ll='ls -la'" >> ~/.bashrc && \
    echo "HISTSIZE=10000" >> ~/.bashrc && \
    echo "HISTFILESIZE=20000" >> ~/.bashrc && \
    echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> ~/.bashrc

# start.sh 스크립트 추가 및 설정
COPY start.sh /usr/local/bin/start.sh
RUN sed -i 's/\r$//' /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

# 포트 노출
EXPOSE 18013

# 시작 스크립트 실행
CMD ["/bin/bash", "/usr/local/bin/start.sh"]