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

# 본인의 GitHub 레포지토리 주소로 정확하게 클론합니다
RUN git clone https://github.com .

# 프로그래밍 환경에 맞춰 빌드 시도 (Makefile이 존재할 경우 가동)
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

# 1단계에서 빌드된 폴더가 있다면 통째로 복사
COPY --from=builder /app /gimps/repo_build

# [안전장치] 만약 레포지토리 빌드본 내에 mprime(또는 prime95) 실행 파일이 없다면,
# 연산이 멈추지 않도록 GIMPS 공식 최신 리눅스 64비트 바이너리를 다운로드하여 대체합니다.
RUN if [ ! -f /gimps/repo_build/mprime ] && [ ! -f /gimps/repo_build/prime95 ]; then \
        echo "레포지토리 내 실행 바이너리가 없어 공식 mprime을 다운로드합니다."; \
        wget https://mersenne.org && \
        tar -zxvf gimps_v30.19.linux64.tar.gz && \
        rm gimps_v30.19.linux64.tar.gz; \
    else \
        if [ -f /gimps/repo_build/mprime ]; then mv /gimps/repo_build/mprime /gimps/mprime; fi; \
        if [ -f /gimps/repo_build/prime95 ]; then mv /gimps/repo_build/prime95 /gimps/mprime; fi; \
    fi

# 실행 권한 부여
RUN chmod +x mprime

# 프라임넷 자동 로그인을 위한 설정 파일 주입 (선택 사항)
# 로컬에 local.txt를 만드셨다면 아래 줄의 주석(#)을 제거하세요
# COPY local.txt ./

# Fly.io 백그라운드 구동을 위한 비대화형 자동 모드(-m) 실행
CMD ["./mprime", "-m"]
