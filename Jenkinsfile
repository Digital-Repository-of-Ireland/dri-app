pipeline {
    agent {
        docker {
            image 'dri-jenkins-agent'
            label 'master'
            args '-u jenkins:jenkins -v rvm:/home/jenkins/.rvm -v /var/lib/jenkins/.ssh:/home/jenkins/.ssh'
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
                        ~/.local/bin/aws s3 --endpoint-url=https://objects.dri.ie cp swagger/v1/swagger.json s3://DEPLOY/swagger.json.${BRANCH_NAME}"
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
        stage('Update Mirror') {
            when {
                branch 'develop'
            }
            steps {
                sh './buildshim push'
            }
        }
        stage('Deploy') {
            when {
                branch 'develop'
                environment name: 'SKIP_DEPLOY', value: 'false'
            }
            steps {
                dir('ansible-dri-infrastructure') {
                    git branch: 'master',
                        credentialsId: '5a3ca3b3-d07d-4acd-bfd7-8a308078b6ec',
                        url: 'ssh://git@tracker.dri.ie:2200/drirepo/ansible-dri-infrastructure'
                }
                sh 'sudo /usr/bin/update-alternatives --set python /usr/bin/python2'
                sshagent (credentials: ['5a3ca3b3-d07d-4acd-bfd7-8a308078b6ec']) {
                ansiColor('xterm') {
                    ansiblePlaybook([credentialsId: '5a3ca3b3-d07d-4acd-bfd7-8a308078b6ec',
                                    inventory: 'ansible-dri-infrastructure/inventory/hosts.buildbot',
                                    playbook:  'ansible-dri-infrastructure/site.yml',
                                    vaultCredentialsId: 'ansible-vault',
                                    tags: 'getfacts,dri_app,dri_app_worker',
                                    extraVars: [
                                        deploy_branch: 'develop',
                                    ],
                                    extras: '--extra-vars=base_user=tchpc',
                                    hostKeyChecking: false,
                                    colorized: true])
                }
                }
            }
        }
    }
    post {
        always {
            junit 'spec/reports/*.xml'
            cucumber fileIncludePattern: 'features/reports/*.json'
            chuckNorris()
        }
    }
}
