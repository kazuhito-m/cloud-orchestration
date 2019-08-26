#!/bin/bash
#
# growiのアプチ構成を作る前の「前準備」作業
#

IP_ID_APP=ip-growi
DISK_ID_01='growi-disk-01'
DISK_ID_02='growi-disk-02'

# IP取得
gcloud compute addresses create ${IP_ID_APP}  \
    --global

# Disk作成
gcloud compute disks create ${DISK_ID_01} ${DISK_ID_02} \
    --size=16Gi \
    --type=pd-ssd \
    --zone=asia-northeast1-a 
