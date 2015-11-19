// Groovy workflow script for Jenkins Multibranch Workflow plugin
def org_name = 'cloudhotspot'
def repo_name = 'todobackend'

node {
    checkout scm

    try {
        stage 'Build application artefacts'
        sh 'make build'

        // Requires Zentimestamp plugin for BUILD_TIMESTAMP variable
        stage 'Tag release image'
        def tags = [ "${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}", "latest" ]
        echo "tags: ${tags.size()}"
        for (tag in tags) { 
            echo "each ${tag}"
            sh "make tag ${tag}"
        }

        stage 'Publish release image'
        def images = []
        tags.each { tag -> 
            images << docker.image("${org_name}/${repo_name}:${tag}")
        }
        docker.withRegistry("https://registry.hub.docker.com", "docker-registry") {
          images.each { image -> image.push() }
        }
    }
    finally {
        stage 'Clean up'
        sh 'make clean'
    }
}