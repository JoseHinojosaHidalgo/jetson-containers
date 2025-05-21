#---
# name: odm_orin
# alias: odm_orin:latest
# group: robots
#---
ARG BASE_IMAGE
FROM dustynv/opendronemap:r36.3.0


RUN apt-get update && \
    apt-get install -y --no-install-recommends \
		  valgrind \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

COPY run_odm_orin.sh /code/run_odm_orin.sh

#ENTRYPOINT ["python3", "/code/run.py"]
