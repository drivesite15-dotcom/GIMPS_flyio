# 기존 캐시를 완전히 무력화하기 위해 구조를 단순화한 최종본입니다.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /gimps

# 오류가 나던 git clone 단계를 완전히 지우고, 
# GIMPS 공식 최신 리눅스 64비트 연산 프로그램을 직접 다운로드합니다.
RUN wget https://mersenne.org && \
    tar -zxvf gimps_v30.19.linux64.tar.gz && \
    rm gimps_v30.19.linux64.tar.gz

RUN chmod +x mprime

# Fly.io 백그라운드에서 끊김 없이 자동 연산하도록 설정 (-m)
CMD ["./mprime", "-m"]
