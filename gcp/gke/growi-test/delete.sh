#!/bin/bash
for i in growi-app elasticsearch mongo namespace
do
  kubectl delete -f ./${i}.yaml
done
