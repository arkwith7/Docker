## 네트워크 연결이 안되는 서버에서 개발환경을 구축하기 위한 도커 이미지 만들기

### 1. 도커 이미지 만들기
#### 1.1 Dockerfile 만들기

```
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
```

#### 1.2 Docker이미지 실행시 시작 스크립트 만들기
그리고 이상의 Dockerfile파일이 위치하는 디렉토리에 start.sh 스크립트를 다음과 같이 작성합니다:
```
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
```


#### 1.3 Docker이미지 빌드 및 실행
이제 도커 이미지를 빌드합니다:
```
docker build \
--build-arg TZ=Asia/Seoul \
--build-arg LLM_SERVICE_URL=$(grep LLM_SERVICE_URL .env | cut -d '=' -f2) \
--build-arg EMBEDDING_SERVICE_URL=$(grep EMBEDDING_SERVICE_URL .env | cut -d '=' -f2) \
--build-arg DOC_PARSER_SERVICE_URL=$(grep DOC_PARSER_SERVICE_URL .env | cut -d '=' -f2) \
--build-arg UPSTAGE_API_KEY=$(grep UPSTAGE_API_KEY .env | cut -d '=' -f2) \
-t rag-dev-terminal .
```

그리고 이미지의 생성 여부 확인후

```
samuel@RAG_SRV:~/Dev/Docker$ docker images
REPOSITORY         TAG       IMAGE ID       CREATED              SIZE
rag-dev-terminal   latest    9b1a5a90b81c   About a minute ago   2.39GB
```

이제 생성된 `rag-dev-terminal` 이미지를 사용하여 컨테이너를 실행합니다.

```
docker run -it -p 18019:18013 \
    --env-file .env \
    -v $(pwd):/workspace \
    -v /home/samuel/local-python-package:/local-packages:ro \
    -v /mnt/c/Rbrain/PJT/workspace/docs:/workspace/host_docs \
    -v /mnt/c/Rbrain/PJT/workspace/extracted_texts:/workspace/extracted_texts \
    -v /home/genai/softcamp:/workspace/softcamp \
    --name rag_dev_container \
    rag-dev-terminal
```

여기서 주의할 점은 호스트의 파일 시스템을 컨테이너에 마운트할 때, 호스트의 디렉토리 경로가 호스트의 실제 경로와 일치하는지 확인해야 합니다. 
예를 들어, 위의 예제에서는 
- '/home/samuel/local-python-package' -- 개발한경에서 사용할 파이썬 패키지 파일(.whl, .tar등),
- '/mnt/c/Rbrain/PJT/workspace/docs' -- 호스트의 보험기초서류 및 기타 문서 파일들,
- '/mnt/c/Rbrain/PJT/workspace/extracted_texts' -- PDF파일에서 추출된 텍스트 파일들
- '/home/genai/softcamp' -- DRM걸린 파일에 대한 암복호화를 위한 라이브러리와 설정 및 가이드 파일들

호스트의 디렉토리 경로가 호스트의 실제 경로와 일치하지 않을 수 있습니다. 이 경우, 호스트의 실제 경로를 사용하여 디렉토리를 마운트해야 합니다.

#### 1.3.1 .env 파일에 환경변수를 설정

도커이미지 빌드를 위한 Dockerfile파일과 같은 디렉토리에 위치한 .env 파일에 환경변수를 설정해야 합니다.
```
LLM_SERVICE_URL=https://api.upstage.ai/v1/solar
EMBEDDING_SERVICE_URL=https://api.upstage.ai/v1/solar
DOC_PARSER_SERVICE_URL=https://api.upstage.ai/v1/document-ai/document-parse
UPSTAGE_API_KEY=up_?????
```

추가적으로 기존 호스트에 도커로 업스테이지 서비스가 실행되고 있을때는, 
다음과 같이 도커 네트워크를 사용하여 다른 서비스들과 연결해야 합니다:

#### 1.3.2 먼저 도커 네트워크를 생성합니다:

```
docker network create rag_api_network
```
만약에 이미 네트워크가 존재한다면 다음 명령어로 네트워크를 확인할 수 있습니다:
```
docker network ls
```
그리고 구체적인 네트워크 정보는 다음 명령어로 확인할 수 있습니다:
```
docker network inspect rag_api_network
```
또한 네트워크를 삭제하려면 다음 명령어를 사용합니다:
```
docker network rm rag_api_network
```
특정 IP 대역을 사용하는 네트워크를 생성하려면 다음 명령어를 사용합니다:
```
docker network create --subnet=10.172.33.0/24 rag_api_network
```

`rag_api_network`의 IP 대역 10.172.33.0/24의 네트워크를 생성하였습니다. 이를 통해 10.172.33.1부터 10.172.33.254까지의 IP를 사용할 수 있습니다.

#### 1.3.3 기존의 API 서비스 컨테이너들을 이 네트워크에 연결합니다:
```
docker network connect rag_api_network llm_service
docker network connect rag_api_network embadding_service
docker network connect rag_api_network doc_parser_service
```

#### 1.3.4 주피터랩 컨테이너를 실행할 때 이 네트워크에 연결합니다:
```
docker run -it -p 18019:18013 \
    --env-file .env \
    -v $(pwd):/workspace \
    -v /home/samuel/local-python-package:/local-packages:ro \
    -v /mnt/c/Rbrain/PJT/workspace/docs:/workspace/host_docs \
    -v /mnt/c/Rbrain/PJT/workspace/extracted_texts:/workspace/extracted_texts \
    -v /home/genai/softcamp:/workspace/softcamp \
    --network rag_api_network \
    --name rag_dev_container \
    rag-dev-terminal
```

#### 1.3.5 주피터랩 컨테이너를 백그라운드로 실행:
```
docker run -d -p 18019:18013 \
    --env-file .env \
    -v $(pwd):/workspace \
    -v /home/samuel/local-python-package:/local-packages:ro \
    -v /mnt/c/Rbrain/PJT/workspace/docs:/workspace/host_docs \
    -v /mnt/c/Rbrain/PJT/workspace/extracted_texts:/workspace/extracted_texts \
    -v /home/genai/softcamp:/workspace/softcamp \
    --network rag_api_network \
    --name rag_dev_container \
    rag-dev-terminal
```
이렇게 하면 컨테이너가 백그라운드에서 실행되며, 터미널은 즉시 제어권을 돌려받게 됩니다. 컨테이너 ID가 출력되고 바로 프롬프트로 돌아갑니다.

실행한 컨테이너가 잘 실행되는지를 확인하고 싶다면, 다음 명령어를 사용할 수 있습니다:
```
docker logs rag_dev_container
```

컨테이너에 접속해야 할 경우, 다음 명령어를 사용할 수 있습니다:
```
docker exec -it rag_dev_container /bin/bash
```
#### 1.3.6 도커이미지 재빌드:
```
docker build --no-cache \
  --build-arg TZ=Asia/Seoul \
  --build-arg LLM_SERVICE_URL=$(grep LLM_SERVICE_URL .env | cut -d '=' -f2) \
  --build-arg EMBEDDING_SERVICE_URL=$(grep EMBEDDING_SERVICE_URL .env | cut -d '=' -f2) \
  --build-arg DOC_PARSER_SERVICE_URL=$(grep DOC_PARSER_SERVICE_URL .env | cut -d '=' -f2) \
  --build-arg UPSTAGE_API_KEY=$(grep UPSTAGE_API_KEY .env | cut -d '=' -f2) \
  -t rag-dev-terminal:latest .
```
 - --no-cache: 이 옵션은 이전 빌드의 캐시를 사용하지 않고 모든 단계를 새로 실행합니다. 이는 모든 변경사항이 확실히 적용되도록 합니다.

### 2. 컨테이너에서 개발하기

`http://{호스트 IP}:18019/lab` 에 접속하여 주피터랩 환경에서 개발합니다.

이 설정의 주요 특징은 다음과 같습니다:
- 1. 기본 Ubuntu 최신 이미지를 사용하고 있습니다.
- 2. 필요한 시스템 패키지들을 설치하고 있습니다. Java 11, git, vim, nano 등이 포함되어 있어 다양한 개발 작업이 가능합니다.
- 3. Python 3.11을 설치하고 가상환경을 생성하여 사용합니다.
- 4. Bash 설정 파일을 생성하여 터미널 사용성을 개선하고 있습니다.
- 5. JupyterLab과 다양한 데이터 과학, 머신러닝 관련 Python 패키지들을 설치하고 있습니다.
- 6. 필요한 작업 디렉토리들을 생성하고 있습니다.
- 7. 환경 변수를 ARG를 통해 빌드 시 설정할 수 있도록 하고 있습니다.
- 8. 시작 스크립트를 추가하고 실행 권한을 부여하고 있습니다.

주요 설치 패키지:
- JupyterLab, pandas, numpy, matplotlib, seaborn, scikit-learn
- PDF 처리 관련: PyMuPDF, PyPDF2, pdfplumber
- 자연어 처리 관련: konlpy, kiwipiepy
- 머신러닝/딥러닝 관련: langchain, faiss-cpu, chromadb
- 웹 개발 관련: fastapi, uvicorn

또한 호스트의 파이썬 패키지를 컨테이너에 마운트하여 사용할 수 있도록 설정합니다:

- 1. 처음 접속하면 JupyterLab과 터미널 세션이 모두 실행됩니다.
- 2. 호스트의 '/local-packages' 디렉토리가 컨테이너 내부의 '/local-packages' 디렉토리로 읽기 전용으로 마운트됩니다.
- 3. 사용자는 터미널에서 직접 `pip install --no-index --find-links=/local-packages <package_name>` 명령을 사용하여 패키지를 설치할 수 있습니다.
- 4. 호스트의 '/local-packages' 디렉토리에 특정 패키지의 설치 파일(*.whl, *.tar.gz)이 존재한다면, 아래와 같이 컨테이너 내부의 터미널에서 패키지를 설치할 수 있습니다:

```
pip install --no-index --find-links=/local-packages <package_name>
```

이 환경은 데이터 과학, 머신러닝, 웹 개발 등 다양한 Python 기반 개발 작업을 수행하기에 적합합니다.
	
#### 2.1 파이썬 코드에서 다른 API 서비스들에 접근하기

이렇게 설정하면 주피터랩 컨테이너 내에서 다른 API 서비스들에 접근할 수 있습니다. 파이썬 코드에서는 다음과 같이 환경 변수를 사용하여 API에 접근할 수 있습니다:
```
import os

llm_url = os.environ['LLM_SERVICE_URL']
embedding_url = os.environ['EMBEDDING_SERVICE_URL']
doc_parser_url = os.environ['DOC_PARSER_SERVICE_URL']
api_key = os.environ['UPSTAGE_API_KEY']

# OpenAI 패키지 사용 예
from openai import OpenAI # openai==1.2.0

client = OpenAI(
    api_key=api_key,
    base_url=llm_url
)

# 업스테이지 LLM 서비스 사용 예
stream = client.chat.completions.create(
    model="solar-pro",
    messages=[
        {
            "role": "user",
            "content": "안녕하세요, 요즘 어때요?"
        }
    ],
    stream=True,
)

for chunk in stream:
    if chunk.choices[0].delta.content is not None:
        print(chunk.choices[0].delta.content, end="")
        
```

### 3. 네트워크 연결이 안되는 서버에서 Docker 이미지 설치 절차

이 과정은 크게 세 단계로 나눌 수 있습니다: 이미지 저장, 이미지 전송, 이미지 로드.

#### 3.1 이미지 저장(네트워크가 연결된 원본 서버에서)

먼저, 네트워크 연결이 되는 원본 서버에서 이미지를 저장합니다.

```
docker save -o rag-dev-terminal.tar rag-dev-terminal
```
이 명령어는 'rag-dev-terminal' 이미지를 'rag-dev-terminal.tar'라는 파일로 저장합니다.

#### 3.2 이미지 전송

물리적 매체(예: USB 드라이브, 외장 하드 등)를 사용하여 'rag-dev-terminal.tar' 파일을 업무 담당자와 협의하여 네트워크가 연결되지 않은 서버로 전송합니다.


#### 3.3 이미지 로드(네트워크가 연결되지 않은 서버에서)
'rag-dev-terminal.tar'라는 파일을 USB를 이용하여 네트워크가 연결되지 않은 서버에서 로드하고,
도커 로드 명령어를 사용하여 이미지를 로드합니다.

```
docker load -i rag-dev-terminal.tar
```

이 명령어는 'rag-dev-terminal.tar' 파일을 로드하여 'rag-dev-terminal' 이미지를 생성합니다.

#### 3.4 이미지 확인 및 실행

이미지가 로드되면, `1.3 Docker이미지 빌드 및 실행`에서 설명한 도커 실행 명령어를 사용하여 컨테이너를 백그러운드로 실행합니다.

이미지 확인 
```
docker images
```

이미지 실행
```
docker run -d -p 18019:18013 \
    --env-file .env \
    -v $(pwd):/workspace \
    -v /path/to/local-python-package:/local-packages:ro \
    -v /path/to/docs:/workspace/host_docs \
    -v /path/to/extracted_texts:/workspace/extracted_texts \
    -v /home/genai/softcamp:/workspace/softcamp \
    --name rag_dev_container \
    rag-dev-terminal
```

이 명령어로 로드된 이미지를 사용하여 컨테이너를 실행합니다. 단, 볼륨 마운트 경로는 새 서버의 환경에 맞게 조정해야 합니다.
>> **주의사항:**
 - .env 파일도 함께 전송해야 합니다.
 - 컨테이너 볼륨 마운트 포인트에 연결할 파이썬 패키지 .whl, .tar 파일도 TAR 파일로 압축하여 함께 전송해야 합니다.

    필요한 파이썬 패키지가 requirements.txt에 있을 경우, 다음과 같이 파일 압축

        1. 필요한 패키지 다운로드:

        pip download -r requirements.txt -d ./local-python-package
        
        2. 다운로드된 패키지 압축:

        tar -czvf local-python-package.tar.gz ./local-python-package
        
        이 과정을 통해 `local-python-package.tar.gz` 파일이 생성됩니다.

 - 볼륨으로 마운트하는 디렉토리들(/workspace/host_docs, /workspace/extracted_texts)도 새 서버에 미리 준비되어 있어야 합니다.
>>>1. '/home/samuel/local-python-package' -- 개발한경에서 사용할 파이썬 패키지 파일(.whl, .tar등),

>>>2. '/mnt/c/Rbrain/PJT/workspace/docs' -- 호스트의 보험기초서류 및 기타 문서 파일들,

>>>3. '/mnt/c/Rbrain/PJT/workspace/extracted_texts' -- PDF파일에서 추출된 텍스트 파일들

>>>4. '/home/genai/softcamp' -- DRM걸린 파일에 대한 암복호화를 위한 라이브러리와 설정 및 가이드 파일들

 - 새 서버의 환경(디렉토리 구조, 사용자 권한 등)에 따라 볼륨 마운트 경로를 적절히 수정해야 할 수 있습니다.

이렇게 하면 네트워크가 연결되지 않은 서버에서도 'rag-test-terminal' Docker 이미지를 사용할 수 있습니다.


