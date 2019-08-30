#!/bin/bash
#
# growiのアプチ構成を作る前の「前準備」作業
#

IP_ID_APP=ip-growi
DISK_ID_01='disk-growi-01'
DISK_ID_02='disk-growi-02'

# IP取得
gcloud compute addresses create ${IP_ID_APP}  \
    --global

# Disk作成
gcloud compute disks create ${DISK_ID_01} ${DISK_ID_02} \
    --size=10Gi \
    --type=pd-standard \
    --zone=asia-northeast1-a
