#!/bin/bash

kubectl rollout restart deployment svs-app-frontend --context 127
kubectl rollout restart deployment svs-app-catalog --context 127
kubectl rollout restart deployment svs-app-appointments --context 127
kubectl rollout restart deployment svs-app-customer --context 127