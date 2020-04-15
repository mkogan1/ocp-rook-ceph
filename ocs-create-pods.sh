#! /bin/bash

OC="$(realpath "${OC:-"$(command -v oc)"}")"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit 1

# And machinesets for OCS
#OCS_INSTANCE_TYPE="m5.4xlarge"
OCS_INSTANCE_TYPE="m5a.8xlarge"
OCS_PER_AZ=1
MACHINESETS=$("$OC" -n openshift-machine-api get machinesets -o custom-columns=name:metadata.name,replicas:spec.replicas --no-headers  | grep ' 1' | grep -v ocs | awk '{ print $1 }')
for ms in $MACHINESETS; do
        "$OC" -n openshift-machine-api get "machinesets/$ms" -ojson |\
        jq --arg inst "$OCS_INSTANCE_TYPE" --arg rep $OCS_PER_AZ '.metadata.name=.metadata.name+"-ocs"|.spec.selector.matchLabels."machine.openshift.io/cluster-api-machineset"=.metadata.name|.spec.template.metadata.labels."machine.openshift.io/cluster-api-machineset"=.metadata.name|.spec.template.metadata.labels."cluster.ocs.openshift.io/openshift-storage" = ""|.spec.template.spec.providerSpec.value.instanceType=$inst|.spec.replicas=($rep|tonumber)|.spec.template.spec.metadata.labels."cluster.ocs.openshift.io/openshift-storage" = ""' |\
        "$OC" -n openshift-machine-api apply -f -
done
"$OC" -n openshift-machine-api get machinesets

