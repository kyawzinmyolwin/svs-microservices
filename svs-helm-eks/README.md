Location to run: vagrant@DevOpsProject-box:~/svs-microservices$

helm upgrade --install svs ./svs-helm \
  -f svs-helm/values.yaml \
  -f svs-helm/kind-values.yaml