// Groovy workflow script for Jenkins Multibranch Workflow plugin
def org_name = 'cloudhotspot'
def repo_name = 'todobackend'
def docker_registry = 'https://registry.hub.docker.com'
def docker_credential = 'docker-registry'

node {
    checkout scm

    try {
        stage 'Run unit/integration tests'
        try { sh 'make test' }
        catch(all) {
            step([$class: 'JUnitResultArchiver', testResults: '**/reports/*.xml'])
            error 'Test Failure'
        }

        stage 'Build application artefacts'
        sh 'make build'

        stage 'Create release environment and run acceptance tests'
        try { sh 'make release' }
        catch(all) {
            step([$class: 'JUnitResultArchiver', testResults: '**/reports/*.xml'])
            error 'Test Failure'
        }
        step([$class: 'JUnitResultArchiver', testResults: '**/reports/*.xml'])

        // Requires Zentimestamp plugin for BUILD_TIMESTAMP variable
        stage 'Tag and publish release image'
        def buildTag = "${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}"
        def commitTag = "${env.BRANCH_NAME}.\$(git rev-parse --short HEAD)"
        sh "make tag ${buildTag}"
        sh "make tag ${commitTag}"
        pushImage(buildTag, org_name, repo_name, docker_registry, docker_credential)
        pushImage(commitTag, org_name, repo_name, docker_registry, docker_credential)
        if (env.BRANCH_NAME == 'master') {
            sh 'make tag latest'
            pushImage('latest', org_name, repo_name, docker_registry, docker_credential)
        }
    }
    finally {
        stage 'Clean up'
        sh 'make clean'
    }
}

// Functions
def pushImage(tag, org_name, repo_name, docker_registry, docker_credential) {
    def image = docker.image("${org_name}/${repo_name}:${tag}")
    docker.withRegistry(docker_registry, docker_registry) {
        image.push()
    }
}


