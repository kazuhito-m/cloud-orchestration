#!/bin/sh -x

# GKE上にクラスタを作成するためのスクリプト。
# あらかじめ、以下のことをしておくこと
#
# sudo gcloud components update
# gcloud auth login
# https://console.cloud.google.com/apis/api/container.googleapis.com/overview?project=${PROJECT_NAME} から、APIを許可

# ---- config part ---

if [ $# -ne 1 ]; then
    echo "引数が正しくありません。第一引数に config-* ファイルを指定してください。"
    exit 1
fi
config_file=${1}
if [ ! -e ${config_file} ]; then
    echo "引数が正しくありません。指定された config ファイルがありません。"
    exit 2
fi
. ${config_file}

# kickしたディレクトリから、このスクリプトのあるディレクトリに移動。
cd $(cd $(dirname $0);pwd)
. ./config.properties

# ---- create part ----

gcloud config set project ${PROJECT_NAME}

gcloud config set compute/zone ${REGION}-a

# Create VPC
gcloud compute networks create ${NETWORK_NAME} \
    --subnet-mode custom
gcloud compute networks subnets create ${SUBNNET_NAME} \
    --network ${NETWORK_NAME} \
    --region ${REGION} \
    --range ${RANGE}
gcloud compute firewall-rules create ${NETWORK_NAME}-rule01 \
    --network ${NETWORK_NAME} \
    --allow tcp:80,icmp

# Create GKE Clusters
gcloud container clusters create ${CLUSTER_NAME} \
    --network=${NETWORK_NAME} \
    --subnetwork=${SUBNNET_NAME} \
    --machine-type=${GKE_MACHINE_TYPE} \
    --num-nodes=${GKE_NODES_COUNT} \
    --enable-ip-alias \
    --cluster-ipv4-cidr=/16 \
    --services-ipv4-cidr=/22
gcloud container clusters get-credentials ${CLUSTER_NAME}
