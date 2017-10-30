#!/bin/bash

# RUN with sudo

apt-get install -y python-pip python-dev build-essential 
pip install -y --upgrade pip
pip install awscli

curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get update

apt-cache policy docker-ce

cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

apt-get install -y docker-ce=17.03.1~ce-0~ubuntu-xenial
#apt-get install -y docker.io

usermod -aG docker ubuntu


apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet \
     kubeadm=1.8.2-00 \
     kubectl

cat <<EOF >${HOME}/kubeadm.conf
kind: MasterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha1
cloudProvider: aws
tokenTTL: 0
apiServerExtraArgs:
  cloud-config: /etc/kubernetes/pki/cloud-config
controllerManagerExtraArgs:
  cloud-config: /etc/kubernetes/pki/cloud-config
EOF

mkdir -p /etc/kubernetes/

cat <<EOF >/etc/kubernetes/pki/cloud-config
[Global]
KubernetesClusterTag=kubernetes-development
KubernetesClusterID=kubernetes-development
EOF

chmod 0755 /etc/kubernetes/pki/cloud-config

cat <<EOF >/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cloud-provider=aws --cloud-config=/etc/kubernetes/pki/cloud-config"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests --allow-privileged=true"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_SYSTEM_PODS_ARGS $KUBELET_NETWORK_ARGS $KUBELET_DNS_ARGS $KUBELET_AUTHZ_ARGS $KUBELET_CADVISOR_ARGS $KUBELET_CERTIFICATE_ARGS $KUBELET_EXTRA_ARGS
EOF

JOIN_CMD=`kubeadm init --pod-network-cidr=192.168.0.0/16 | grep "kubeadm join" | sed 's/^ *//g'`
echo $JOIN_CMD

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

aws s3 cp /etc/kubernetes/admin.conf s3://statengine-devops/development-admin.conf

kubectl --kubeconfig /etc/kubernetes/admin.conf apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml

KUBE_JOIN_TOKEN=`kubeadm token create --groups system:bootstrappers:kubeadm:default-node-token --ttl 0`


echo "Non-expiring join token: $KUBE_JOIN_TOKEN"


