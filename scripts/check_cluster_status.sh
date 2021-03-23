#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

function check_installer_ok(){
    echo "waiting for ks-installer pod ready"
    kubectl -n kubesphere-system wait --timeout=180s --for=condition=Ready $(kubectl -n kubesphere-system get pod -l app=ks-install -oname)
    echo "waiting for KubeSphere ready"
    while IFS= read -r line; do
        echo $line
        if [[ $line =~ "Welcome to KubeSphere" ]]
            then
                return
        fi
    done < <(timeout 10 kubectl logs -n kubesphere-system deploy/ks-installer -f)
    echo "ks-install not output 'Welcome to KubeSphere'"
    sleep 20
    exit 1
}

function wait_status_ok(){
    for ((n=0;n<3;n++))
    do
        OK=`kubectl get pod -A| grep -E 'Running|Completed' | wc | awk '{print $1}'`
        Status=`kubectl get pod -A | sed '1d' | wc | awk '{print $1}'`
        echo "Success rate: ${OK}/${Status}"
        if [[ $OK == $Status ]]
        then
            n=$((n+1))
        else
            n=0
            kubectl get all -A
        fi
        sleep 1
    done
}

export -f wait_status_ok

# wait 30m
TIMEOUT="${timeout:-1800}"

timeout $TIMEOUT bash -c wait_status_ok

check_installer_ok