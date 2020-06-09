# !/bin/bash

# Script to check configuration
#  and to test environment


function checkCorrectResponse() {

strURLtoCheck=$1

strResponse=$(curl -s ${strURLtoCheck})

echo "Check response calling to  ${strURLtoCheck}"
echo "$strResponse"
echo " "

if [ ${#strResponse} -le 10 ]; then
        echo "Error! Unable to get correct response ${strURLtoCheck}" ;
        echo "Status: Failure"
        exit
fi

}

function checkCorrectHealthResponse() {

strURLtoCheck=$1

strResponse=$(curl -s ${strURLtoCheck})

echo "Check response calling to  ${strURLtoCheck}"
echo "$strResponse"
echo " "

if [ "$strResponse" != "ok" ]; then
        echo "Error! Unable to get correct response ${strURLtoCheck}" ;
        echo "Status: Failure"
        exit
fi

}


function checkRoundRobinRequestsDistribution() {
	
nChecksNumber=$1
nOfNodes=$2

buckets_of_calls=()

for (( idx=0; idx<${nChecksNumber}; idx++ ))
do  
   strResponse=$(curl -s http://${IpAddressLoadBalancer}/hostname)
   if [ $idx -ge $nOfNodes ]; then
	   arr_idx=$((${idx}%${nOfNodes}))
	   in_the_bucket=${buckets_of_calls[$arr_idx]}
	   if [ "$strResponse" != "$in_the_bucket" ]; then
                     echo "Error! Loadbalancer traffic distributed NOT round-robin!"
                     echo "Status: Failure"
                     exit
	   fi
   fi

   if [[ $idx -ge 1 ]] && [[ $nOfNodes -ge 2 ]]; then
	   arr_idx=$((${idx}-1 % ${nOfNodes}))
	   if [[ $strResponse == $buckets_of_calls[$arr_idx] ]]; then
                     echo "Error! Loadbalancer traffic distributed NOT round-robin!"
                     echo "Status: Failure"
                     exit
           fi
   fi
   
   arr_idx=$((${idx} % ${nOfNodes}))
   buckets_of_calls[$arr_idx]=$strResponse

done	

}

echo " "
echo "----------------------------------------"
echo "Check Configuration and Test Environment"
echo "----------------------------------------"
echo " "

nCheck=`docker ps | grep 'loadbalancer' | wc -l`

if [ "$nCheck" -eq "0" ]; then
   echo "Error! LoadBalancer is not running!";
   echo "Status: Failure"
   exit;
fi

nCheck=`docker ps | grep 'app1' | wc -l`

if [ "$nCheck" -eq "0" ]; then
   echo "Error! App1 is not running!";
   echo "Status: Failure"
   exit;
fi

nCheck=`docker ps | grep 'app2' | wc -l`

if [ "$nCheck" -eq "0" ]; then
   echo "Error! App2 is not running!";
   echo "Status: Failure"
   exit;
fi

ContainerIDLoadBalancer=`docker ps | grep 'loadbalancer' | awk ' { print $1 }';`
ContainerIDApp1=`docker ps | grep 'app1' | awk ' { print $1 }';`
ContainerIDApp2=`docker ps | grep 'app2' | awk ' { print $1 }';`

echo "ContainerID LoadBalancer = $ContainerIDLoadBalancer"
echo "ContainerID App1         = $ContainerIDApp1"
echo "ContainerID App2         = $ContainerIDApp2"

IpAddressLoadBalancer=`docker inspect ${ContainerIDLoadBalancer} | grep 'IPAddress' | tail -1 |  cut -d'"' -f 4`
IpAddressApp1=`docker inspect ${ContainerIDApp1} | grep 'IPAddress' | tail -1 |  cut -d'"' -f 4`
IpAddressApp2=`docker inspect ${ContainerIDApp2} | grep 'IPAddress' | tail -1 |  cut -d'"' -f 4`

echo " "
echo "Load Balancer IP: $IpAddressLoadBalancer"
echo "App1 IP:          $IpAddressApp1"
echo "App2 IP:          $IpAddressApp2"
echo " "

checkCorrectResponse http://${IpAddressLoadBalancer}

checkCorrectHealthResponse http://${IpAddressApp1}:8080/health

checkCorrectHealthResponse http://${IpAddressApp2}:8080/health

checkCorrectHealthResponse http://${IpAddressApp1}:8080/health

checkCorrectHealthResponse http://${IpAddressApp2}:8080/health

checkRoundRobinRequestsDistribution 100 2

echo " "
echo "Status: Success"
echo " "
