def ORG = "mayadata"
def STAGING_KEYPATH="~jenkins/.ssh/id_rsa_control_node_staging"
def PROD_KEYPATH="~jenkins/.ssh/id_rsa_control_node_production"
def PREPROD_KEYPATH="~jenkins/.ssh/id_rsa_control_node_preproduction"
def CONTROL_NODE="35.225.61.42"
def REPO = "grafana"
def DOCKER_HUB_REPO = "https://index.docker.io/v1/"
def DOCKER_IMAGE = ""
def ONPREMORG = "registry.mayadata.io"
env.user="atulabhi"
env.pass="ka879707"
pipeline {
    agent any
    stages {
        stage('Version Update') {
            steps {
            echo "Workspace dir is ${pwd()}"
            script {
                if (env.BRANCH_NAME == 'prod-mo-grafana'){
                  BN = sh(
                    returnStdout: true,
                    script: "./version_override ${REPO}"
                  ).trim()
                echo "${BN}"
                echo "This image will be tagged with ${BN}"
              }else {
                echo "This is not a prod-mo-grafana branch, tagging skipped!!" 
              } 
           }
        }
      }
        stage('Build') {
            steps {
	        script {
	            GIT_SHA = sh(
		                 returnStdout: true,
				 script: "git log -n 1 --pretty=format:'%h'"
				).trim()

		    sh 'env > env.txt'
		    for (String i : readFile('env.txt').split("\r?\n")) {
		        println i
		    }

		    echo "Checked out branch: ${env.BRANCH_NAME}"

                    if (env.BRANCH_NAME == 'prod-mo-grafana') {
                        echo 'Starting build for ${env.BRANCH_NAME} branch'
                        DOCKER_IMAGE = docker.build("${ORG}/maya-${REPO}:${BN}")
                    } else {
                        echo 'Starting build for ${env.BRANCH_NAME} branch'
                        DOCKER_IMAGE = docker.build("${ORG}/maya-${REPO}:${env.BRANCH_NAME}-${GIT_SHA}")
                    }

                }
	         }
        }

        stage('Push to DockerHub') {
            steps {
		    script {
		        echo "Checked out build number: ${env.BUILD_NUMBER}"
		        docker.withRegistry('https://registry.hub.docker.com', 'ddc3fdf7-5611-4d47-a8ab-d0ea7624671a') {
                            if (env.BRANCH_NAME == 'staging-mo-grafana') {
		                echo "Pushing the image with the tag..."
                                sh "docker login --username=mayadata --password=MayaDocker@123 && docker push ${ORG}/maya-${REPO}:${BRANCH_NAME}-${GIT_SHA}"
				//DOCKER_IMAGE.push()
                            } else if (env.BRANCH_NAME == 'prod-mo-grafana') {
			                    echo "Pushing the image with the tag..."
                                sh "docker login --username=mayadata --password=MayaDocker@123 && docker push ${ORG}/maya-${REPO}:${BN}"

                            }
		                 }
		            }
	             }
         }
           stage ('build for ennterprise grafana') {
            steps {
            script {
              withCredentials([usernamePassword( credentialsId: 'f8a4bba1-4ded-4234-ac07-3e7f74b7bec6', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                if (env.BRANCH_NAME == 'enterprise-master') {
                sh """
                 DOCKER_IMAGE = docker.build("${ONPREMORG}/maya-${REPO}:1.0.0-ee")
                 ddocker login https://registry.mayadata.io -u${USERNAME} -p${PASSWORD} && docker push ${ONPREMORG}/maya-${REPO}:1.0.0-ee}
                """
             }
            }    
          }
        }
      }      
        stage ('Adding git-tag for prod-mo-grafana') {
            steps {
            script {
                if (env.BRANCH_NAME == 'prod-mo-grafana') {
                sh """
                 git tag -fa "${BN}" -m "Release of ${BN}"
                 """
                sh 'git tag -l'
                sh """
                 git push https://${env.user}:${env.pass}@github.com/mayadata-io/grafana.git --tag
                 """
             }
          }
        }
      }
        stage('Deploy on the related k8s cluster') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'staging-mo-grafana') {
                        // Deploy to staging cluster
                        echo "${env.BRANCH_NAME}-${GIT_SHA}"
                        sh "ssh -i ${STAGING_KEYPATH} staging@${CONTROL_NODE} \" /home/staging/install.sh maya-grafana \"${env.BRANCH_NAME}-${GIT_SHA}\"\""
                    } else if (env.BRANCH_NAME == 'prod-mo-grafana') {
                        // Deploy to production cluster
                        sh "ssh -i ${PROD_KEYPATH} production@${CONTROL_NODE} \" /home/production/install.sh maya-grafana \"${BN}\"\""
                    } else {
                        echo "Not sure what to do with this branch. So not deploying. May be dev branch ?"
                    }
                }
             }
        }
    } 

    post {
        always {
            echo 'This will always run'
        }
        success {
            echo 'This will run only if successful'
                slackSend channel: '#jenkins-builds',
                   color: 'good',
                   message: "The pipeline ${currentBuild.fullDisplayName} completed successfully :dance: :thumbsup: "
        }
        failure {
            echo 'This will run only if failed'
                slackSend channel: '#jenkins-builds',
                    color: 'RED',
                    message: "The pipeline ${currentBuild.fullDisplayName} failed. :scream_cat: :japanese_goblin: "
        }
        unstable {
            echo 'This will run only if the run was marked as unstable'
        }
        changed {
            echo 'This will run only if the state of the Pipeline has changed'
            echo 'For example, if the Pipeline was previously failing but is now successful'
        }
    }
}
