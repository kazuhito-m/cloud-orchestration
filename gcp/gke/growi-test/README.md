k8s用Growiコンテナ立ち上げセット
==========================

# What's this?

Growi公式が作成している [docker-compose.yaml](https://github.com/weseek/growi-docker-compose/blob/master/docker-compose.yml) を、k8sで再現するべく移植したもの。

# Instration

まず、

# Other

## 既存のデータをmongodbに流し込む方法

1. 立ち上がった後、Growiに管理者アカウントを作り、一度ログインしておく
0. `kubectl get service --namespace growis` などし、 `mongo` サービスの外向けIPを割り出す
0. guiツールなどで割り出したIPとつなぎ、 `growi` DBSを削除する
0. `mongodump` で予め取っておいたダンプを、 `mongorestore --host=[割り出したIP]` で復元する

# TODO

- 本系と違い「データをストレージに分離していない」ので、podが消されてしまうとデータが吹き飛ぶので、永続層に書きたい
