// Groovy workflow script for Jenkins Multibranch Workflow plugin
def org_name = 'cloudhotspot'
def repo_name = 'todobackend'
def docker_registry = 'https://registry.hub.docker.com'
def docker_credential = 'docker-registry'

// Functions
def makeTag(tag) {
    sh 'make tag ${tag}'
}

def pushImage(tag) {
    def image = docker.image("${org_name}/${repo_name}:${tag}")
    docker.withRegistry(docker_registry, docker_registry) {
        image.push()
    }
}

node {
    checkout scm

    try {
        stage 'Build application artefacts'
        sh 'make build'

        // Requires Zentimestamp plugin for BUILD_TIMESTAMP variable
        stage 'Tag and publish release image'
        def buildTag = "${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}"
        makeTag(buildTag)
        pushImage(buildTag)
        if (env.BRANCH_NAME == 'master') {
            makeTag('latest')
            pushImage('latest')
        }
    }
    finally {
        stage 'Clean up'
        sh 'make clean'
    }
}

