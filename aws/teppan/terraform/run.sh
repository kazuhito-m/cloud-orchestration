#!/bin/bash
#
# 「Terraformコマンド実行」スクリプト
#

THIS_SCRIPT_PATH=$(cd $(dirname $(readlink -f $0 || echo $0));pwd -P)

cd ${THIS_SCRIPT_PATH}

terraform plan -var-file="./settings.tfvars" ./

if [ $? -ne 0 ] ; then
  echo 'ドライラン失敗。実行せず終了します。'
  exit 9
fi

terraform apply -var-file="./settings.tfvars" ./
