# 빌더가 완전히 새로운 레이어로 인식하도록 구문을 하나로 완전 통합했습니다.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 패키지 설치부터 GIMPS 바이너리 세팅까지 캐시가 개입할 수 없도록 일괄 처리합니다.
RUN apt-get update && apt-get install -y wget curl ca-certificates && \
    mkdir -p /gimps && cd /gimps && \
    wget --no-check-certificate https://mersenne.org && \
    tar -zxvf gimps_v30.19.linux64.tar.gz && \
    rm gimps_v30.19.linux64.tar.gz && \
    chmod +x /gimps/mprime && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /gimps

# 백그라운드 자동 가동 옵션 부여
CMD ["./mprime", "-m"]
