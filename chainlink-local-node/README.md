Getting started: Running chainlink node locally: 

Prerequisites: 
1. Docker Installed (https://docs.docker.com/desktop/install/windows-install/)
2. Alchemy Account (https://dashboard.alchemy.com/), with an API key to the goreli network (I have been using that blockchain for creating contracts)


Setup:
1. Under .env file, change <MY API KEY> to the API key in your alchemy account
2. Under docker-compose.yml, postgres_chainlink.volumes to match the path to your data folder (Ex. for me its C:/Dev/cas-720-project/chainlink-local-node/data:/var/lib/postgressql/data/)
3. Under docker-compose.yml, postgres_chainlink.volumes to match the path to your data folder (Ex. for me its C:/Dev/cas-720-project/chainlink-local-node/chainlink-volume:/chainlink/)
4. Launch Docker successfully
5. Open a new terminal, change directory to chainlink-local-node folder, and run "docker compose up"
6. Change docker to see if both applications are running successfully
7. go to localhost:6688 to access the chainlink operator terminal (credentials are in the chain-linkvolume/apicredentials.txt)
