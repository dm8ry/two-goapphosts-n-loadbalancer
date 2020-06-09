Purpose:
--------

Create an infrastructure as code that creates a SaaS service environment:

- using Vagrant
- using docker-compose.yml

The service should provide a REST API which serve the HTML home page.
The solution is based on a Linux family OS.

Environment components:
-----------------------

- A load balancer
- 2 application hosts

Load balancer:
--------------

The load balancer listens to the incoming requests to the API and forwards them to one of the application hosts, spreading the load in round robin fashion.
The load balancer should run as a Docker container.

Application host:
-----------------

Runs a Go application inside a Docker container, which will listen to incoming API requests. 

1. / serve the HTML home page 
2. /health basic health check returning 200 Ok
3. /ws simple endpoint for websocker communication

Architecture:
-------------

The environment can be presented as:

- Nginx load balancer
- Two application hosts machines

The load balancer accepts incoming requests and forwards them to one of the two application servers which are prepared to accept them. 
It's done in round robin style. Also it can be done in a weighted style.
Nginx is an example of a proxy which is capable of load balancing. Also there are another load balancers. for example F5.
A load balancer performs the function of receiving the initial requests and making sure that it gets answered by a corresponding application server. 
The 2 application servers are based on Go language.

The Load Balancer runs as a Docker Container.
Each of two application hosts are based on Go language inside a Docker Container.

The structure of source directory:

```

/----
    +-- Vagrantfile
    |
    +-- docker-compose.yml
    |
    +-- README.md
    |
    +-- health_monitor_check.sh
    |
    +------------- lb ----------------+
    |                                 |
    |                                 +------- Dockerfile
    |                                 |
    |                                 +------- nginx.conf
    |
    +------------- app ---------------+
                                      |
                                      +------- Dockerfile
                                      |
                                      +------- main.go
                                      |
                                      +------- go.mod
                                      |
                                      +------- go.sum

```

How to deploy the environment:
------------------------------

The environment can be deployed using docker-composer or using vagrant.

Using docker-composer:
----------------------

docker-compose build

Builds the following images:

```
REPOSITORY                  TAG                 IMAGE ID            CREATED             SIZE
dragontail_d_loadbalancer   latest              8783d04ce24d        44 minutes ago      132MB
dragontail_d_app2           latest              228789363e55        44 minutes ago      821MB
dragontail_d_app1           latest              655c07ad1b1a        44 minutes ago      821MB
```

docker-compose up -d

Starts app1, app2 and loadbalancer:

```
Starting app2 ... done
Starting app1 ... done
Starting loadbalancer ... done
```

docker-compose ps

Should provide output:

```
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                NAMES
534909f7a46f        dragontail_d_loadbalancer   "/docker-entrypoint.…"   45 minutes ago      Up 20 minutes       0.0.0.0:80->80/tcp   loadbalancer
f411e3e4ea95        dragontail_d_app2           "./main"                 45 minutes ago      Up 20 minutes       8080/tcp             app2
8f3091398fb4        dragontail_d_app1           "./main"                 45 minutes ago      Up 20 minutes       8080/tcp             app1
```

docker-compose down

Brings environment down:

```
Stopping loadbalancer ... done
Stopping app2         ... done
Stopping app1         ... done
Removing loadbalancer ... done
Removing app2         ... done
Removing app1         ... done
Removing network dragontail_d_default
```

Using vagrant:
--------------

vagrant up

or 

vagrant reload

vagrant status 

Shows state of environment:

Current machine states:

```
app1                      running (docker)
app2                      running (docker)
loadbalancer              running (docker)
```

vagrant destroy -f

Stops the running machine Vagrant is managing and destroys all resources that were created during the machine creation process.

How to test the environment:
----------------------------

Run bash script ./health_monitor_check.sh

It checks LoadBalancer, App1 and App2 statuses, prints their IPs, and checks connectivity and round-robin distribution.

The output trace will look as follows:

dmi@dmi-lpt:~/dragontail_d$ ./health_monitor_check.sh 

``` 
----------------------------------------
Check Configuration and Test Environment
----------------------------------------
 
ContainerID LoadBalancer = e436fdca055f
ContainerID App1         = 31e36aa5b5ec
ContainerID App2         = bc7b5cc35a7a
 
Load Balancer IP: 172.18.0.4
App1 IP:          172.18.0.2
App2 IP:          172.18.0.3
 
Check response calling to  http://172.18.0.4

<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
</head>
<body>
<h1>Welcome</h1>
<h2>Your IP is: 172.18.0.1</h2>
<p id="ws" style="display: none;">Websocket connection established</p>
<p id="ws-counter" style="display: none;"></p>
<script>  
let counter = 0;
let ws = new WebSocket("ws://" + location.host + "/ws");

ws.onmessage = function(e) {
    counter++;
    document.getElementById("ws").style.display = "block";
    document.getElementById("ws-counter").style.display = "block";
    document.getElementById("ws-counter").innerHTML = "Websocket message count: " + counter;
};

ws.onopen = function(e) {
  console.log("ws connection open")
  ws.send("connection established");
};

ws.onerror = function(error) {
  console.log("error", error.message)
};

setInterval(function(){
    ws.send("tick")
}, 2000);
</script>
</body>
</html>
 
Check response calling to  http://172.18.0.2:8080/health
ok
 
Check response calling to  http://172.18.0.3:8080/health
ok
 
Check response calling to  http://172.18.0.2:8080/health
ok
 
Check response calling to  http://172.18.0.3:8080/health
ok
 
 
Status: Success
 
dmi@dmi-lpt:~/dragontail_d$ 
```

---------------- The End ---------------------

