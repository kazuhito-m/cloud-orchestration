#!/bin/bash
for i in namespace mongo elasticsearch growi-app
do
  kubectl create -f ./${i}.yaml
done
