#!/bin/sh

# GKE上に環境を作成するためのスクリプト。
# あらかじめ、以下のことをしておくこと
#
# sudo gcloud components update
# gcloud auth login

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

# ---- delete part ----

gcloud config set project ${PROJECT_NAME}

gcloud container clusters delete ${CLUSTER_NAME}

echo "削除完了しました。GCPのComputeEngineから、「クラスタに使われていたVMのディスク」を削除してください。"

gcloud sql instances delete ${DB_INSTANCE_NAME}

gcloud compute firewall-rules delete ${NETWORK_NAME}-rule01
gcloud compute networks subnets delete ${SUBNNET_NAME} --region ${REGION}
# コンソールから「ルート」「VPCピアリングネットワーク」「プライベートサービス接続」で属しているものをすべて削除してからでしか、以下を実行できない
# gcloud compute networks delete ${NETWORK_NAME}
