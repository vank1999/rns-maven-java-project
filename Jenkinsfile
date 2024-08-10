def ansible = [:]
         ansible.name = 'ansible'
         ansible.host = '172.31.19.53'
         ansible.user = 'ubuntu'
         ansible.identityFile = '~/.ssh/id_rsa' // Path to the private key
         ansible.allowAnyHosts = true

def kops = [:]
         kops.name = 'kops'
         kops.host = '172.31.42.19'
         kops.user = 'ubuntu'
         kops.identityFile = '~/.ssh/id_rsa'
         kops.allowAnyHosts = true

pipeline {
    agent { label 'slave' }
    tools{
        maven 'maven-3.9'
    }
    stages {
        stage('prepare-workspace') {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'https://github.com/vank1999/rns-maven-java-project.git'
            }
        }

        stage('tools-setup') {
            steps {
            echo "Tools Setup"
            sshCommand remote: ansible, command: 'cd rns-maven-java-project; git pull'
            sshCommand remote: ansible, command: 'cd rns-maven-java-project; ansible-playbook -i hosts tools/sonarqube/sonar-install.yaml'
            sshCommand remote: ansible, command: 'cd rns-maven-java-project; ansible-playbook -i hosts tools/docker/docker-install.yml'  
            
            //K8s Setup
           sshCommand remote: kops, command: "cd rns-maven-java-project; git pull"
	       sshCommand remote: kops, command: "kubectl apply -f rns-maven-java-project/k8s-code/staging/namespace/staging-ns.yml"
	       sshCommand remote: kops, command: "kubectl apply -f rns-maven-java-project/k8s-code/prod/namespace/prod-ns.yml"
            }
        }

        stage('sonarqube analysis'){
            steps{
                 echo "Sonar Scanner"
                 sh "mvn clean compile"
                 withSonarQubeEnv('sonarqube') { 
                 sh "mvn sonar:sonar "
                }
            }
        }


      stage('Build Code') {
        
          steps{
              sh "mvn package -DskipTests=true"  
          }
          post{
              success{
                  archiveArtifacts '**/*.war'
              }
          }
      }

          stage('Publish to Nexus') {
            steps {
             nexusArtifactUploader artifacts:
              [
                [
                    artifactId: 'java-maven',
                     classifier: '',
                      file: 'target/ java-maven-1.0-SNAPSHOT.war',
                       type: 'war'
                       ]
                       ],
                        credentialsId: 'nexus-credentials',
                         groupId: 'com.example',
                          nexusUrl: '3.91.66.159',
                           nexusVersion: 'nexus2',
                            protocol: 'http',
                             repository: 'java-maven',
                              version: '1.0-SNAPSHOT'
            }
        }

        stage('Build Docker Image') {
         
         steps{
                  sh "docker build -t vank1999/webapp ."  
         }
     }

        stage('Publish Docker Image') {
         
        steps{

    	      withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'dockerPassword', usernameVariable: 'dockerUser')]) {
    		    sh "docker login -u ${dockerUser} -p ${dockerPassword}"
	      }
        	sh "docker push vank1999/webapp"
         }
    }

        stage('Deploy to Staging') {
	
	      steps{
	      //Deploy to K8s Cluster 
              echo "Deploy to Staging Server"
	      sshCommand remote: kops, command: "cd rns-maven-java-project; git pull"
	      sshCommand remote: kops, command: "kubectl delete -f rns-maven-java-project/k8s-code/staging/app/deploy-webapp.yml"
	      sshCommand remote: kops, command: "kubectl apply -f rns-maven-java-project/k8s-code/staging/app/."
	  }		    
     }

          stage ('Integration-Test') {
	
	        steps {
             echo "Run Integration Test Cases"
            sh "mvn clean verify -DskipTests=true"
        }
      }

   stage ('approve') {
	steps {
		echo "Approval State"
                timeout(time: 7, unit: 'DAYS') {                    
			input message: 'Do you want to deploy?', submitter: 'admin'
		}
	  }
     }

    stage ('Prod-Deploy') {
	
	  steps{
              echo "Deploy to Production"
	      //Deploy to Prod K8s Cluster
	      sshCommand remote: kops, command: "cd rns-maven-java-project; git pull"
	      sshCommand remote: kops, command: "kubectl delete -f rns-maven-java-project/k8s-code/prod/app/deploy-webapp.yml"
	      sshCommand remote: kops, command: "kubectl apply -f rns-maven-java-project/k8s-code/prod/app/."
	 }
	}
  }
}
