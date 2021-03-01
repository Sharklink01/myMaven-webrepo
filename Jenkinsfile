node ('slave1') {
    cleanWs()
    def mvnHome = tool 'localMaven'
	stage ('checkout code'){
        checkout([$class: 'GitSCM', branches: [[name: '**']], doGenerateSubmoduleConfigurations: false, extensions: [pruneTags(true)], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'ce186163-be7f-4c44-81b9-2c6334ad6f96', refspec: '+refs/tags/*:refs/remotes/origin/tags/*', url: 'https://github.com/Sharklink01/myMaven-webrepo.git']]])
	}
	stage ('Build'){
		sh "${mvnHome}/bin/mvn clean install"
	}
	stage ('Sonar Code Quality and Jacoco Coverage')  {
        withSonarQubeEnv(credentialsId: '19f585d4-3420-4b09-869d-79a3ab651f9f') {
        sh "${mvnHome}/bin/mvn sonar:sonar"
        }
	}
	stage ('Archive Artifacts'){
		archiveArtifacts allowEmptyArchive: true, artifacts: '**/*.war', followSymlinks: true
	}
	stage ('Artifactory Upload') {
        nexusArtifactUploader artifacts: [[artifactId: 'myMaven-web', classifier: '', file: 'target/myMaven-web.war', type: 'WAR']], credentialsId: '36d30814-0659-4df7-b0cc-e1fc79d48c9c', groupId: 'com.devslink.web', nexusUrl: '3.21.179.194:8081', nexusVersion: 'nexus3', protocol: 'http', repository: 'maven-snapshots', version: '0.0.1-SNAPSHOT'
	}
}
node ('master') {
    cleanWs()
    stage ('Artifactory Pull to master Node') {
        checkout([$class: 'GitSCM', branches: [[name: '**']], doGenerateSubmoduleConfigurations: false, extensions: [pruneTags(true)], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'ce186163-be7f-4c44-81b9-2c6334ad6f96', refspec: '+refs/tags/*:refs/remotes/origin/tags/*', url: 'https://github.com/Sharklink01/myMaven-webrepo.git']]])
        sh 'curl -u $NEXUS_USER:$NEXUS_PASSWORD -X GET --output myMaven-web.war -L "http://3.21.179.194:8081/service/rest/v1/search/assets/download?sort=version&repository=maven-snapshots&group=com.devslink.web&maven.baseVersion=0.0.1-SNAPSHOT&maven.extension=WAR&maven.classifier" -H "accept: application/json"'
        sh 'mkdir target && mv myMaven-web.war target/myMaven-web.war'
    }
	stage ('Docker Build and Docker Push') {
        withDockerServer([uri: 'unix:///var/run/docker.sock']) {
            withDockerRegistry(credentialsId: '1c6e5992-6ba2-4d11-a554-5c426285e4db', url: 'https://index.docker.io/v1/') {
            image = docker.build("sharklink01/mymaven-web:${env.BUILD_NUMBER}")
            image.push()
            }
        }
    try {
        stage('Docker Cleanup') {
            sh 'docker ps -f name=deploy_mavenweb -q | xargs --no-run-if-empty docker container stop'
            sh 'docker container ls -a -fname=deploy_mavenweb -q | xargs -r docker container rm'
        }
        stage ('Docker DEV Deploy') {
            echo 'Deploying to Docker Tomcat Container'
            sh 'docker run --name deploy_mavenweb -d -p 5000:8080 sharklink01/mymaven-web:$BUILD_NUMBER'
        }
        stage ('DEV Approve')  {
            echo "Taking approval from DEV Manager"
            timeout(time: 1, unit: 'HOURS') {
            input message: 'Do you want to Deploy?', ok: 'Approve', submitter: 'admin'
            }
        }
        stage ('Slack notification')  {
            slackSend(color: 'good', channel: '#jenkins-build-channel', message: "Job Successfull, here is the info -  Job '${env.JOB_NAME}, Build# [${env.BUILD_NUMBER}]', Node: ${env.NODE_NAME} (${env.BUILD_URL})")
        }
    } 
    catch (Exception e) {
        sh 'docker ps -f name=deploy_mavenweb -q | xargs --no-run-if-empty docker container stop'
        //sh 'docker container ls -a -fname=deploy_mavenweb -q | xargs -r docker container rm'
        echo e.toString()
        currentBuild.result = "FAILURE"
        echo "Jenkins Pipeline Failed !! Check logs"
            stage ('Slack notification')  {
                slackSend(color: 'warning', channel: '#jenkins-build-channel', message: "Job Failed, here is the info -  Job '${env.JOB_NAME}, Build# [${env.BUILD_NUMBER}]', Node: ${env.NODE_NAME} (${env.BUILD_URL})")
            }
	}
}
