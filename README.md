# Linode Node Balancer Auto SSL

## How this works

This uses certbot and Lets Encrypt to perform a dns-01 challenge, which basically updates your DNS record with a temporary TXT entry to validate ownership. Using certbot will automatically schedule a systemd job that will continuously update the cert.

The update_nodebalancer_job.sh script schedules a job that runs every 12 hours and updates a Node Balancer with the certs.

There's no limit to the number of domains or Node Balancers this process can maintain.

## Requirements

- Linode as your DNS provider
- A Linode Access Token with Read\Write access to Domains and Node Balancers
- Root Access

## How to use

1.  Migrate your DNS records to Linode if you haven't already done so.
2.  Provision a Linode to perform the SSL renewal. A nanode is fine. This has only been tested with Ubuntu 22.04.
3.  Create a API Access Token with Read\Write Privileges to Domains and Node Balancers.
4.  Log in as root user.
5.  Follow the steps [here](https://certbot.eff.org/instructions?ws=other&os=ubuntufocal&tab=wildcard) to install certbot. When you get to the step "Install correct DNS plugin" use Linode - ie:

    > `sudo snap install certbot-dns-linode`

6.  Follow the instruction [here](https://certbot-dns-linode.readthedocs.io/en/stable/) to create the credentials.ini file.
7.  Run certbot. The command will look something like _(This automatically creates a scheduled systemd job that will continuously renew the cert)_ :

    > certbot certonly \
    >  --dns-linode \
    >  --dns-linode-credentials ~/linode.ini \
    >  --dns-linode-propagation-seconds 120 \
    >  -d mysite.com \
    >  -d www.mysite.com

8.  Your certs will then be located in this directory:
    > `/etc/letsencrypt/live/mysite.com/`

The certificate and private key paths will be (replace mysite with your domain):

> `/etc/letsencrypt/live/mysite.com/fullchain.pem`
> `/etc/letsencrypt/live/mysite.com/privkey.pem`

9. Run the update_nodebalancer_job.sh file with the following arguments. You'll need to use the Linode CLI or API to retrieve the Node Balancer and Config Id's. NAME is used to name the systemd job that's scheduled which can be anything. Ie: "mysitecom"

> sudo bash create_systemd_job.sh <NODE_BALANCER_ID> <CONFIG_ID> <PRIVATE_KEY_PATH> <CERTIFICATE_PATH> <API_TOKEN> <NAME>

10. Your node balancer will now have the cert and will auto renew. For each additional Node Balancer, repeat steps 7-10.
