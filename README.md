# cicd-test
Simple test project for learning cicd with a nodejs app, github, and jenkins using DigitalOcean.

### Notes
I have some configurations differently than in the tutorial. Notably, my `package.json` and my jenkins build step.

```json
  // inside package.json
  "scripts": {
    "test": "mocha --exit"
  },
```
This enables me to test the project with `npm test`. Secondly, my jenkins build step:
```sh
rm -rf node_modules
npm install
npm t
ssh <user>@<NODE.SERVER.IP> <<EOF
 cd ~/cicd-test
 git pull
 rm -rf node_modules
 npm install -production
 pm2 restart all
 exit
EOF
```

## Resources
* [Medium Tutorial](https://medium.com/@mosheezderman/how-to-set-up-ci-cd-pipeline-for-a-node-js-app-with-jenkins-c51581cc783c): covers entire setup process.
* [Digital Ocean Tutorial](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-18-04): on configuring a jenkins droplet, for which the above tutorial is out-of-date.