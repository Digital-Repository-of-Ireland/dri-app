pipeline {
    agent {
        docker { 
            image 'dri-jenkins-agent'
            label 'Jenkins'
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
        stage('Deploy') {
            when {
                branch 'develop'
            }
            steps {
                sh './buildshim push'
                dir('ansible-dri-infrastructure') {
                    git branch: 'master',
                        credentialsId: '5a3ca3b3-d07d-4acd-bfd7-8a308078b6ec',
                        url: 'ssh://git@tracker.dri.ie:2200/drirepo/ansible-dri-infrastructure'
                }
                sh 'sudo /usr/bin/update-alternatives --set python /usr/bin/python2.7'
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
        }
    }
}
