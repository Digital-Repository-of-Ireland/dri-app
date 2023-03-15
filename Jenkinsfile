pipeline {
    agent {
        docker {
            image 'dri-jenkins-agent'
            label 'master'
            args '-u jenkins:jenkins --network jenkins -v rvm:/home/jenkins/.rvm -v /var/lib/jenkins/.ssh:/home/jenkins/.ssh -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --group-add docker'
        }
    }
    stages {
        stage('Configure') {
            steps {
                sh './buildshim configure'
            }
        }
        stage('RSpec') {
            steps {
                sh './buildshim rspec'
            }
        }
        stage('API') {
            steps {
                sh './buildshim api'
                withCredentials(
                [[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    credentialsId: 'aws-s3-deploy',  // ID of credentials in Jenkins
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    echo "Upload Swagger JSON to S3."
                    sh "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
                        AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
                        AWS_REGION=us-east-1 \
                        /home/jenkins/.local/bin/aws s3 --endpoint-url=https://objects.dri.ie cp swagger/v1/swagger.json s3://deploy/swagger.json.${BRANCH_NAME}"
                }
            }
        }
        stage('Cucumber') {
            steps {
                sh './buildshim cucumber'
            }
        }
        stage('Compile') {
            steps {
                sh './buildshim compile'
            }
        }
    }
    post {
        always {
            junit 'spec/reports/*.xml'
            cucumber fileIncludePattern: 'features/reports/*.json'
        }
        success {
          publishHTML target: [
              allowMissing: false,
              alwaysLinkToLastBuild: false,
              keepAll: true,
              reportDir: 'coverage',
              reportFiles: 'index.html',
              reportName: 'RCov Report'
            ]
        }
    }
}
