Solution Is Below
Part I

1) Run the container image infracloudio/csvserver:latest in background and check if it's running.

docker run -d infracloudio/csvserver:latest

2) If it's failing then try to find the reason, once you find the reason, move to the next step.

$ docker ps -a

CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS                      PORTS     NAMES

248ad28906d7   infracloudio/csvserver:latest   "/csvserver/csvserver"   59 seconds ago   Exited (1) 58 seconds ago             peaceful_williams

$ docker logs 248ad28906d7

2022/09/16 13:22:52 error while reading the file "/csvserver/inputdata": open /csvserver/inputdata: no such file or directory


3) Write a bash script gencsv.sh to generate a file named inputFile whose content looks like

0, 234
1, 98
2, 34

Developed Sample Shell script called gencsv.sh and the output is stored in file inputFile.

#!/bin/sh
for (( i = 0; i < ${1:-10}; i++ ));
do
  echo "$i, $RANDOM" >> inputFile
done

chmod +r inputFile

4)Run the container again in the background with file generated in (3) available inside the container (remember the reason you found in (2)).

     docker run -d -v /c/Users/visha/inputFile:/csvserver/inputdata infracloudio/csvserver:latest

C:\Users\visha>docker ps

f60bde174def   infracloudio/csvserver:latest   "/csvserver/csvserver"   16 seconds ago   Up 12 seconds   9300/tcp   bold_mcnulty


sh-4.4# pwd
/csvserver
sh-4.4# ls
csvserver  inputdata
sh-4.4# cat inputdata
0, 4596
1, 24200
2, 15364
3, 20988
4, 3166
5, 9742
6, 32268
7, 28539
8, 3255
9, 28560
sh-4.4#

5) Get shell access to the container and find the port on which the application is listening. Once done, stop / delete the running container.

 docker inspect f60bde174def

            "Ports": {
                "9300/tcp": null
            },


sh-4.4# netstat -anp | grep "9300"
tcp6       0      0 :::9300                 :::*                    LISTEN      1/csvserver

Stopping and Deleting container

 docker stop f60bde174def
 
 docker rm f60bde174def


6) Same as (4), run the container and make sure,
The application is accessible on the host at http://localhost:9393
Set the environment variable CSVSERVER_BORDER to have value Orange.

docker run -d -p 9393:9300 -e CSVSERVER_BORDER=Orange -v /c/Users/visha/inputFile:/csvserver/inputdata infracloudio/csvserver:latest

f65de0f535724f96c3ed433a6d9dd98b5145087719e2633052dc9ed9cb8c3010

![image](https://user-images.githubusercontent.com/58246130/190657656-14ce4633-2092-43a0-8468-95168faff6f0.png)

$ curl -s localhost:9393
<!DOCTYPE html>
<html>
<head>
  <title>CSV Server</title>
  <style>
  th, td {
    padding: 5px;
  }
  </style>
</head>
<body>
<!-- Y3N2c2VydmVyIGdlbmVyYXRlZCBhdDogMTY2MzMzNjk4Mg== -->
<h3 style="border:3px solid Orange">Welcome to the CSV Server</h3><table><tr><th>Index</th><th>Value</th></tr><tr><td>0</td><td> 4596</td></tr><tr><td>1</td><td> 24200</td></tr><tr><td>2</td><td> 15364</td></tr><tr><td>3</td><td> 20988</td></tr><tr><td>4</td><td> 3166</td></tr><tr><td>5</td><td> 9742</td></tr><tr><td>6</td><td> 32268</td></tr><tr><td>7</td><td> 28539</td></tr><tr><td>8</td><td> 3255</td></tr><tr><td>9</td><td> 28560</td></tr></table></body></html>

==============================================================================

PART II:
1. Delete any containers running from the last part.
   docker stop f65de0f53572

   docker rm f65de0f53572
    
2. Create a docker-compose.yaml file for the setup from part I.
    version: "3.9"
    services:
      csvserver:
        hostname: csvserver
        image: infracloudio/csvserver:latest
        ports:
          - "9393:9300"
        volumes:
          - ./inputFile:/csvserver/inputdata
        environment:
          - CSVSERVER_BORDER=Orange
          
3.One should be able to run the application with docker-compose up.
    docker-compose up -d
    
    Starting visha_csvserver_1 ...
    
    Starting visha_csvserver_1 ... done

    docker ps
    
162439a77404   infracloudio/csvserver:latest   "/csvserver/csvserver"   4 minutes ago   Up 3 minutes   0.0.0.0:9393->9300/tcp   visha_csvserver_1


$ curl -s localhost:9393
<!DOCTYPE html>
<html>
<head>
  <title>CSV Server</title>
  <style>
  th, td {
    padding: 5px;
  }
  </style>
</head>
<body>
<!-- Y3N2c2VydmVyIGdlbmVyYXRlZCBhdDogMTY2MzMzODc0OA== -->
<h3 style="border:3px solid Orange">Welcome to the CSV Server</h3><table><tr><th>Index</th><th>Value</th></tr><tr><td>0</td><td> 4596</td></tr><tr><td>1</td><td> 24200</td></tr><tr><td>2</td><td> 15364</td></tr><tr><td>3</td><td> 20988</td></tr><tr><td>4</td><td> 3166</td></tr><tr><td>5</td><td> 9742</td></tr><tr><td>6</td><td> 32268</td></tr><tr><td>7</td><td> 28539</td></tr><tr><td>8</td><td> 3255</td></tr><tr><td>9</td><td> 28560</td></tr></table></body></html>
==============================================================================================================

Part III

0. Delete any containers running from the last part.

docker stop 162439a77404

docker rm 162439a77404

1. Add Prometheus container (prom/prometheus:v2.22.0) to the docker-compose.yaml form part II.

     version: "3.9"
     services:
       csvserver:
         hostname: csvserver
         image: infracloudio/csvserver:latest
         ports:
           - "9393:9300"
         volumes:
           - ./inputFile:/csvserver/inputdata
         environment:
           - CSVSERVER_BORDER=Orange
      
       prometheus:
         hostname: prometheus
         image: prom/prometheus:v2.22.0
         ports:
           - "9090:9090"
         volumes:
           - ./prometheus:/etc/prometheus/
         command:
            - '--web.enable-lifecycle'
            - '--config.file=/etc/prometheus/prometheus.yaml'  

2. Configure Prometheus to collect data from our application at <application>:<port>/metrics endpoint. (Where the <port> is the port from I.5)

![image](https://user-images.githubusercontent.com/58246130/190675129-6f271713-0ff8-4363-9556-6ff80c603203.png)
