Instructions to run project:
1) Ensure docker and docker-compose are installed in the virtual machines the code will be implemented on.
2) Three virtual machines are required. One to implement the user microservice, one for the rides microservice, and one for the orchestrator DBaaS service.
3) There is a folder called Project. Open that and you will find three folders, one for each service. Copy the contents of the each of those 3 folders, not the folders themselves, into the root directory of your VM's. For example, copy the contents of the folder Orchestrator_Main_Folder into your VM such that the docker-compose.yml file and folder Project are in the root directory of that VM. Do the same for the other 2 folders.
4) Grant the user in each VM root priveledges for docker. Ensure that the name of the root user for the Orchestrator service is called ubuntu.
5) While in the root folder of each of these instances, run the same command below in each VM to create docker images and containers and start the application:
    docker-compose up
6) The users and rides VM is load balanced, so any calls to them are usually placed over the load balancer. Public IP of load balancer is :
     Users-Rides-1846279167.us-east-1.elb.amazonaws.com
7) The orchestrator VM has been assigned an elastic IP address. That IP address is : 
    54.152.249.57
