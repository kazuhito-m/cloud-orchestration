#!/bin/bash
#
# 「Terraformコマンド実行」スクリプト
#

THIS_SCRIPT_PATH=$(cd $(dirname $(readlink -f $0 || echo $0));pwd -P)

cd ${THIS_SCRIPT_PATH}

if [ ! -d '.terraform' ]; then
  terraform init
fi

terraform plan ./

if [ $? -ne 0 ] ; then
  echo 'ドライラン失敗。実行せず終了します。'
  exit 9
fi

terraform apply ./
