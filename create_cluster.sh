#!/bin/bash
printf '%s \n'  "-----------------------"
printf '%s \n'  " Creating EKS cluster"
printf '%s \n'  "-----------------------"

# Check required variables
varsok=true

if  [ -z "$AWS_REGION" ]; then echo AWS_REGION must be set && varsok=false; fi
if  [ -z "$AWS_PROJECT" ]; then echo AWS_PROJECT must be set && varsok=false; fi
#if  [ -z "$AWS_CODECOMMIT_REPO" ]; then echo AWS_CODECOMMIT_REPO must be set && varsok=false; fi
if  [ -z "$AWS_EKS_NODES" ]; then echo AWS_EKS_NODES must be set && varsok=false; fi
#if  [ -z "$AWS_EKS_CLUSTERNAME" ]; then echo AWS_EKS_CLUSTERNAME must be set && varsok=false; fi

if  [ "$varsok" = false ]; then printf '%s\n' "Missing variables" && exit ; fi

aws_cluster_exists="false"
aws_clusters=( `eksctl get clusters -o json| jq '.[].metadata.name'` ) 
for i in "${!aws_clusters[@]}"; do
  #printf "%s" "cluster $i =  ${aws_clusters[$i]}.........."
  if [[ "${aws_clusters[$i]}" =~ "${AWS_PROJECT}" ]]; then
      printf "%s\n" "Reusing existing EKS cluster:  ${AWS_PROJECT}"
      aws_cluster_exists="true"
      break
  fi
done

if [[ "${aws_cluster_exists}" = "true" ]]; then
    printf "%s\n" "Reusing existing cluster  ${AWS_PROJECT}"
else
    printf '%s\n' "Creating file: work/${AWS_PROJECT}EksCluster.yml..."
    cat << EOF > work/${AWS_PROJECT}EksCluster.yml
# This file is (re-) generated by code.
# Any manual changes will be overwritten.
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: ${AWS_PROJECT}
  region: ${AWS_REGION}
  tags:
    ${TAGKEY0}: ${TAGVALUE0}
    ${TAGKEY1}: ${TAGVALUE1}
    ${TAGKEY2}: ${TAGVALUE2}
managedNodeGroups:
  - name: nodegroup
    desiredCapacity: ${AWS_EKS_NODES}
    iam:
      withAddonPolicies:
        albIngress: true
    tags:
      ${TAGKEY1}: ${TAGVALUE1}
      ${TAGKEY2}: ${TAGVALUE2}
EOF
    start_time="$(date -u +%s)"
    printf '%s\n' "Creating a ${AWS_EKS_NODES}-node eks cluster named: ${AWS_PROJECT} in region ${AWS_REGION}"
    printf '%s\n' "This may take up to 20 minutes... (started at:`date`)"
    starttime=`date +%s`
    eksctl create cluster -f work/${AWS_PROJECT}EksCluster.yml   #non-fargate EKS cluster
    #eksctl create cluster --name=${AWS_PROJECT}.fargate --fargate --tags Key=${TAGKEY0},Value=${TAGVALUE0} Key=${TAGKEY1},Value=${TAGVALUE1} Key=${TAGKEY2},Value=${TAGVALUE2}  #EKS cluster with Fargate profile
    #printf '%s\n' "Waiting for Cloudformation stack \"managed-smartcheck-cluster\" to be created."
    #aws cloudformation wait stack-create-complete --stack-name eksctl-managed-smartcheck-cluster  --region $AWS_REGION
    #printf '%s\n' "Waiting for Cloudformation stack \"managed-smartcheck-nodegroup-nodegroup\" to be created.  This may take a while"
    #aws cloudformation wait stack-create-complete --stack-name eksctl-eksctl-managed-smartcheck-nodegroup-nodegroup	 --region $AWS_REGION
    endtime="$(date +%s)"
    printf '%s\n' "Cloudformation Stacks deployed.  Elapsed time: $((($endtime-$starttime)/60)) minutes"
    printf '%s\n' "Checking EKS cluster.  You should see your EKS cluster in the list below "
    eksctl get clusters
  fi
