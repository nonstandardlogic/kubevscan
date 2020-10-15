# kubevscan

## Install sidecar injector

The project uses a sidecar injector to create for each pod a vulnerability scan container based on the open source  [Trivy](https://github.com/aquasecurity/trivy).

The chosen sidecar injector is the open source [k8s-sidecar-injector](https://github.com/tumblr/k8s-sidecar-injector)

The following steps describe the installation and configuration of the sidecar inector.

First step is to pull the docker image :

    $ docker pull tumblr/k8s-sidecar-injector
    Using default tag: latest
    latest: Pulling from tumblr/k8s-sidecar-injector
    Status: Downloaded newer image for tumblr/k8s-sidecar-injector:latest
    docker.io/tumblr/k8s-sidecar-injector:latest

Second step is generating the TLS certs
    
Edit the ca.conf and csr-prod.conf
 
    $ cd kubevscan/config/tls/
    $ export ORG="nonstandardlogic" DOMAIN="nonstandardlogic.com"
    $ sed -i -e "s|__ORG__|$ORG|g" -e "s|__DOMAIN__|$DOMAIN|g" ca.conf csr-prod.conf

Install Ruby
    
    $ sudo apt update
    $ sudo apt install ruby-full
    $ ruby --version
      ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux-gnu

Generate certs

    $ DEPLOYMENT=london CLUSTER=CLUSTER ./new-cluster-injector-cert.rb
    All done!
    Here are your certs for london-DEV
    Generated new certs for london-DEV for k8s-sidecar-injector

The certs are available in the sub directory london/DEV


Update MutatingWebhookConfiguration file

This step updates the MutatingWebhookConfiguration file with the ca.crt used to sign the TLS certs

    $ export DEPLOYMENT="london" CLUSTER="DEV"
    $ CABUNDLE_BASE64="$(cat config/tls/$DEPLOYMENT/$CLUSTER/ca.crt |base64|tr -d '\n')"
    $ echo $CABUNDLE_BASE64
    LS0tLS1CRUdJTiBDRVJUSUZJQ0.......
    $  sed -i -e "s|__CA_BUNDLE_BASE64__|$CABUNDLE_BASE64|g"  ./kubernetes/mutating-webhook-configuration.yaml 


Creates Kubernetes secret 

    $ kubectl create secret generic k8s-sidecar-injector --from-file=config/tls/${DEPLOYMENT}/${CLUSTER}/sidecar-injector.crt --from-file=config/tls/${DEPLOYMENT}/${CLUSTER}/sidecar-injector.key --namespace=kube-system
    secret/k8s-sidecar-injector created

Check secrets

    $ kubectl get secrets --namespace=kube-system | grep k8s-sidecar-injector
    k8s-sidecar-injector                             Opaque                                2      79s

    $ kubectl describe  secret k8s-sidecar-injector --namespace=kube-system
        Name:         k8s-sidecar-injector
        Namespace:    kube-system
        Labels:       <none>
        Annotations:  <none>

        Type:  Opaque

        Data
        ====
        sidecar-injector.crt:  1809 bytes
        sidecar-injector.key:  1679 bytes

Deploy the kubernetes manifests

    $ kubectl apply -f kubernetes/clusterrole.yaml 
    clusterrole.rbac.authorization.k8s.io/k8s-sidecar-injector created

    $ kubectl apply -f kubernetes/clusterrolebinding.yaml 
    clusterrolebinding.rbac.authorization.k8s.io/k8s-sidecar-injector created

    $ kubectl apply -f kubernetes/serviceaccount.yaml 
    serviceaccount/k8s-sidecar-injector created

    $ kubectl apply -f kubernetes/service.yaml 
    service/k8s-sidecar-injector-prod created 

    $ kubectl apply -f kubernetes/deployment.yaml 
    deployment.apps/k8s-sidecar-injector-prod created

    $ kubectl apply -f kubernetes/mutating-webhook-configuration.yaml 
    mutatingwebhookconfiguration.admissionregistration.k8s.io/tumblr-sidecar-injector-webhook created

Deploy the sample ConfigMap with Nginx sidecar config

    $ kubectl create -f kubernetes/configmap-sidecar-test.yaml
    configmap/sidecar-test created
    configmap/test-config created

Check sidecar injector logs

    $ kubectl logs --tail=60 -n kube-system -l k8s-app=k8s-sidecar-injector
    172.18.0.1 - - [15/Oct/2020:14:29:30 +0000] "GET /health HTTP/2.0" 200 12 "" "kube-probe/1.18"
    I1015 14:36:37.504124       1 main.go:131] triggering ConfigMap reconciliation
    I1015 14:36:37.504153       1 watcher.go:151] Fetching ConfigMaps...
    I1015 14:36:37.508225       1 watcher.go:158] Fetched 1 ConfigMaps
    I1015 14:36:37.508488       1 watcher.go:179] Loaded InjectionConfig test1 from ConfigMap sidecar-test:test1
    I1015 14:36:37.508515       1 watcher.go:164] Found 1 InjectionConfigs in sidecar-test
    I1015 14:36:37.508521       1 main.go:137] got 1 updated InjectionConfigs from reconciliation
    I1015 14:36:37.508525       1 main.go:151] updating server with newly loaded configurations (1 loaded from disk, 1 loaded from k8s api)
    I1015 14:36:37.508531       1 main.go:153] configuration replaced
    172.18.0.1 - - [15/Oct/2020:14:36:40 +0000] "GET /health HTTP/2.0" 200 12 "" "kube-probe/1.18"
    
Deploy the pod with the sidecar specs

    $ kubectl create -f kubernetes/debug-pod.yaml
    pod/debian-debug created

Check sidecar injection in the pod description

    $ kubectl describe -f kubernetes/debug-pod.yaml
    Name:         debian-debug
    Namespace:    default
    Priority:     0
    Node:         minikube/172.17.0.2
    Start Time:   Thu, 15 Oct 2020 15:44:38 +0100
    Labels:       <none>
    Annotations:  injector.tumblr.com/request: test1
                injector.tumblr.com/status: injected
    Status:       Pending
    IP:           
    IPs:          <none>
    Containers:
    debian-debug:
        Container ID:  
        Image:         debian:jessie
        Image ID:      
        Port:          <none>
        Host Port:     <none>
        Command:
        sleep
        3600
        State:          Waiting
        Reason:       ContainerCreating
        Ready:          False
        Restart Count:  0
        Environment:
        HELLO:  world
        TEST:   test_that
        Mounts:
        /tmp/test from test-vol (rw)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-fmbdm (ro)
    sidecar-nginx:
        Container ID:   
        Image:          nginx:1.12.2
        Image ID:       
        Port:           80/TCP
        Host Port:      0/TCP
        State:          Waiting
        Reason:       ContainerCreating
        Ready:          False
        Restart Count:  0
        Environment:
        ENV_IN_SIDECAR:  test-in-sidecar
        HELLO:           world
        TEST:            test_that
        Mounts:
        /tmp/test from test-vol (rw)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-fmbdm (ro)
    Conditions:
    Type              Status
    Initialized       True 
    Ready             False 
    ContainersReady   False 
    PodScheduled      True 
    Volumes:
    default-token-fmbdm:
        Type:        Secret (a volume populated by a Secret)
        SecretName:  default-token-fmbdm
        Optional:    false
    test-vol:
        Type:        ConfigMap (a volume populated by a ConfigMap)
        Name:        test-config
        Optional:    false
    QoS Class:       BestEffort
    Node-Selectors:  <none>
    Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                    node.kubernetes.io/unreachable:NoExecute for 300s
    Events:
    Type    Reason     Age   From               Message
    ----    ------     ----  ----               -------
    Normal  Scheduled  57s   default-scheduler  Successfully assigned default/debian-debug to minikube
    Normal  Pulling    56s   kubelet, minikube  Pulling image "debian:jessie"
    Normal  Pulled     15s   kubelet, minikube  Successfully pulled image "debian:jessie"
    Normal  Created    14s   kubelet, minikube  Created container debian-debug
    Normal  Started    14s   kubelet, minikube  Started container debian-debug
    Normal  Pulling    14s   kubelet, minikube  Pulling image "nginx:1.12.2"
