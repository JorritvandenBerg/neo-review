# NEO Review
Smart contracts pose potential security risks, which has already has already led to the loss of millions of dollars worth of digital assets. Peer reviewing code can help to prevent vulnerabilities. NEO Review is a tool for developers to review smart contracts and share best practices. NEO Review is based on ReviewBoard from https://www.reviewboard.org. ReviewBoard has extensive usage documentation, which can be found on https://www.reviewboard.org/docs/. For that reason, this README will be limited to deployment of this project, logging and how to make back-ups.

## Deployment
NEO Review is designed to be deployed and configured with Docker Compose (as far as possible). First get Docker Compose, if you not have it already. Information on how to install Docker Compose can be found on https://docs.docker.com/compose/install/. 

### GitHub OAuth integration
NEO Review has a pre-installed plugin to authenticate with Github credentials, this does needs to be configured though. First, a GitHub Client ID and Secret need to be created via the page https://github.com/settings/applications/new. Fill in "reviewboard-oauth" as Application name and the URL on which NEO Review will be hosted as Homepage URL and register the application. Save the Client ID and Client Secret displayed on the GitHub page.  

### Setting environment variables
Inside the main directory there are two .env files. Copy the secrets.sample.env file under the name "secrets.env" and do the same for common.sample.env under common.env. Change the default values in secrets.env and common.env to the settings for your deployment. For the values of GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET, use the Client ID and Client Secret obtained in the step above. REVIEWBOARD_EMAIL should be the emailaddress of the NEO Review admin.

### Webserver configuration
NEO Review is served with Apache mod_wsgi over http. Typically one would use a reverse proxy server in front of this. The file reversed_proxy_example.conf contains an example configuration for a Nginx reverse proxy server running on Docker as well. IMPORTANT: the example does not account for SSL offloading and redirection of http to https, which is mandatory for good security. 

Note that the server_name (Nginx) or ServerName variable (Apache) MUST exactly match the DOMAIN environment variable in common.env, otherwise a request results in a HTTP status 400 error.

### Deploy the containers
Make sure that the environment variables are set. The reviewboard Docker container will fail to start if one is missing.

To deploy the project, run the following commands in a terminal from the main directory:
1. docker-compose build
2. docker-compose up -d

An initialization script is executed the first time the containers are started. It might take a few minutes before the website is up.

Once reviewboard is deployed, one needs to do the following to activate the GitHub OAuth integration:
1. Sign in as admin user (board_admin by default)
2. Select Admin in the user drop-down menu
3. Click on Extensions in the top bar
4. Enable rb-oauth extension by clicking enable
5. Go to the Authentication tab in the side bar
6. Select OAuth as Authentication Method and Save
 
## Logging
By default logging is disabled, but it can be switched on from the Admin panel. Login as admin user, click Admin in the user drop-down menu and select Logging in the left navigation bar. Select the check-box Enable logging, as Logging directory, /var/www/reviewboar/data can be entered.

To view the reviewboard log, run "docker exec -it neoreview_reviewboard_1 cat /var/www/reviewboard/data/reviewboard.log" from a terminal. The Docker containers have to be running for this.
To view the MYSQL error log, run "docker exec -it neoreview_mysql_1 tail -f /var/log/mysql/error.log".

## Back-ups
Data in Docker containers is non-persistent, unless saved with a data volume. The MYSQL data of NEO Review are kept in named volume mysql_data. The blogpost http://loomchild.net/2017/03/26/backup-restore-docker-named-volumes/ provides a good explanation on how to create back-ups with Docker.
