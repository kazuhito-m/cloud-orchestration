k8s用Growiコンテナ立ち上げセット
==========================

## What's this?

Growi公式が作成している [docker-compose.yaml](https://github.com/weseek/growi-docker-compose/blob/master/docker-compose.yml) を、k8sで再現するべく移植したもの。

## Instration

まず、本家から [Dockerfile](https://github.com/weseek/growi-docker-compose/blob/master/Dockerfile) を落とし、ローカルビルドしたものを、GCPの `Container Registry` に上げる。

```bash
# 予め、GCPにプロジェクトが作ってあることを前提とする。
GCP_PROJECT=$(gcloud config get-value project)
git clone https://github.com/weseek/growi-docker-compose.git growi
cd growi
docker build -t asia.gcr.io/$GCP_PROJECT/growi-for-compose:3.0 .
gcloud docker -- push asia.gcr.io/$GCP_PROJECT/growi-for-compose:3.0
```

次に、 `kubectl` は当該のプロジェクト/クラスタに設定した後、以下のスクリプトを実行する。

```bash
./create.sh
```

しばらく経ったら、サービスの外向けIPが発行されてるか確認後、そのIPへブラウザでアクセスしてみる。

```bash
kubectl get service growi --namespace growis

NAME    TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)   AGE
growi   LoadBalancer   10.3.254.110   [ここのIP]   80:32427/TCP   4m
```

削除する際は、以下のスクリプトを実行する。

```bash
./delete.sh
```

## Other

### 既存のデータをmongodbに流し込む方法

1. 立ち上がった後、Growiに管理者アカウントを作り、一度ログインしておく
0. `kubectl get service --namespace growis` などし、 `mongo` サービスの外向けIPを割り出す
0. guiツールなどで割り出したIPとつなぎ、 `growi` DBSを削除する
0. `mongodump` で予め取っておいたダンプを、 `mongorestore --host=[割り出したIP]` で復元する

## TODO

- 本家と違い「データをストレージに分離していない」ので、podが消されてしまうとデータが吹き飛ぶので、永続層に書きたい
- HTTPS化(DNSとLet'sEncryptで)
- Funtionを使った遠隔地へのバックアップ
