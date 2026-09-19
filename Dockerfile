# ==========================================
# 1단계: 소스 코드 복사 및 빌드 시도 (Multi-stage Build)
# ==========================================
FROM ubuntu:22.04 AS builder

# 필수 빌드 도구 설치
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 요청하신 GitHub 레포지토리 클론 및 파일 준비
RUN git clone https://github.com .

# 프로그래밍 환경에 맞춰 빌드 시도 (Makefile이 있을 경우)
RUN if [ -f Makefile ]; then make; fi


# ==========================================
# 2단계: 실제 Fly.io에서 실행될 경량화 이미지
# ==========================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /gimps

# 1단계에서 빌드된 파일이 있다면 복사
COPY --from=builder /app /gimps/repo_build

# [안전장치] 만약 레포지토리 빌드본에 mprime 실행 파일이 없다면, 
# GIMPS 공식 최신 리눅스 64비트 바이너리(mprime)를 다운로드하여 세팅합니다.
RUN if [ ! -f /gimps/repo_build/mprime ]; then \
        echo "레포지토리 내 바이너리가 없어 공식 mprime을 다운로드합니다."; \
        wget https://mersenne.org && \
        tar -zxvf gimps_v30.19.linux64.tar.gz && \
        rm gimps_v30.19.linux64.tar.gz; \
    else \
        mv /gimps/repo_build/mprime /gimps/mprime; \
    fi

# 실행 권한 부여
RUN chmod +x mprime

# Fly.io는 지속적인 연산을 수행하므로 대화형 모드가 아닌 자동(Automated) 모드로 실행해야 합니다.
# -m: 공식 프롬프트 없이 백그라운드/비대화형 모드로 실행하는 옵션입니다.
CMD ["./mprime", "-m"]
