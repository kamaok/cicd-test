pipeline {
  agent {
     //label 'linux-slave1'
     label 'master'
  }
 
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '3')
    disableConcurrentBuilds()
    timestamps()
  }
  environment {
        DockerImageName = 'my-nodejs-app'
        DockerTag = "${BUILD_NUMBER}"
        AppPort = '3000'
        ContainerName = "${DockerImageName}"
  }
  
  // Should be configurede on Jenkins configuration
  tools {nodejs "node"}
 
  stages {
        
    stage('Cloning Git') {
      steps {
        git 'https://github.com/kamaok/cicd-test.git'
      }
    }
        
    stage('Install dependencies') {
      steps {
        sh 'rm -rf node_modules'
        sh 'npm install'
      }
    }
     
    stage('Test') {
      steps {
         sh 'npm test'
      }
    }
    
    stage('Docker build') {
      steps {
          withCredentials([usernamePassword(credentialsId: 'docker-hub-authentification', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')])
          {
             sh "docker build -t ${DOCKER_USER}/${DockerImageName}:${DockerTag} ."
             sh "docker tag ${DOCKER_USER}/${DockerImageName}:${DockerTag} ${DOCKER_USER}/${DockerImageName}:latest"
           }
      }   
    }
    stage('Docker push to Docker-registry') {
      steps {
         withCredentials([usernamePassword(credentialsId: 'docker-hub-authentification', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')])
          {
              sh "docker login --username ${DOCKER_USER} --password ${DOCKER_PASSWORD}"
              sh "docker push ${DOCKER_USER}/${DockerImageName}:${DockerTag}"
              sh "docker push ${DOCKER_USER}/${DockerImageName}:latest"
              sh "docker rmi -f ${DOCKER_USER}/${DockerImageName}:${DockerTag}"
              sh "docker rmi -f ${DOCKER_USER}/${DockerImageName}:latest"
          }
      }
    }
    
    stage('Deploy to Stage server') {
        //agent { label 'linux-slave2' }
        agent { label 'aws-jenkins-slave-1' }
      steps {
         withCredentials([usernamePassword(credentialsId: 'docker-hub-authentification', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')])
          {
              sh "docker login --username ${DOCKER_USER} --password ${DOCKER_PASSWORD}"
              sh "docker pull ${DOCKER_USER}/${DockerImageName}:latest"
              sh "docker ps -f name=${ContainerName} -q | xargs --no-run-if-empty docker stop"
              sh "docker run --rm -d -p ${AppPort}:3000 --name ${ContainerName} ${DOCKER_USER}/${DockerImageName}:latest"
              sh '''echo "Application is available on the URL: $(curl -s http://169.254.169.254/latest/meta-data/public-hostname):${AppPort}"'''
          }
      }
    }
  }
  post {
      always {
               emailext body: "${currentBuild.currentResult}: Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}\n More info at: ${env.BUILD_URL}",
                recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
                subject: "Jenkins Build ${currentBuild.currentResult}: Job ${env.JOB_NAME}"
      }
  }
  
}
