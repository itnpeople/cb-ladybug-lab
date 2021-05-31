#!/bin/bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: httpbin-1
  labels:
    app: httpbin-1
spec:
  containers:
  - image: docker.io/honester/httpbin:latest
    imagePullPolicy: IfNotPresent
    name: httpbin
  nodeName: $1
---
apiVersion: v1
kind: Pod
metadata:
  name: httpbin-2
  labels:
    app: httpbin-2
spec:
  containers:
  - image: docker.io/honester/httpbin:latest
    imagePullPolicy: IfNotPresent
    name: httpbin
  nodeName: $2
---
apiVersion: v1
kind: Pod
metadata:
  name: httpbin-3
  labels:
    app: httpbin-3
spec:
  containers:
  - image: docker.io/honester/httpbin:latest
    imagePullPolicy: IfNotPresent
    name: httpbin
  nodeName: $3
---
apiVersion: v1
kind: Pod
metadata:
  name: httpbin-4
  labels:
    app: httpbin-4
spec:
  containers:
  - image: docker.io/honester/httpbin:latest
    imagePullPolicy: IfNotPresent
    name: httpbin
  nodeName: $4
---
apiVersion: v1
kind: Pod
metadata:
  name: httpbin-5
  labels:
    app: httpbin-5
spec:
  containers:
  - image: docker.io/honester/httpbin:latest
    imagePullPolicy: IfNotPresent
    name: httpbin
  nodeName: $5
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-1
spec:
  selector:
    app: httpbin-1
  ports:
    - protocol: TCP
      port: 80
      name : "http"
    - protocol: TCP
      port: 5201
      name: "iperf3"
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-2
spec:
  selector:
    app: httpbin-2
  ports:
    - protocol: TCP
      port: 80
      name : "http"
    - protocol: TCP
      port: 5201
      name: "iperf3"
---

apiVersion: v1
kind: Service
metadata:
  name: httpbin-3
spec:
  selector:
    app: httpbin-3
  ports:
    - protocol: TCP
      port: 80
      name : "http"
    - protocol: TCP
      port: 5201
      name: "iperf3"
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-4
spec:
  selector:
    app: httpbin-4
  ports:
    - protocol: TCP
      port: 80
      name : "http"
    - protocol: TCP
      port: 5201
      name: "iperf3"
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-5
spec:
  selector:
    app: httpbin-5
  ports:
    - protocol: TCP
      port: 80
      name : "http"
    - protocol: TCP
      port: 5201
      name: "iperf3"
EOF
