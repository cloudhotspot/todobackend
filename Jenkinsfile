// Groovy workflow script for Jenkins Multibranch Workflow plugin
def org_name = 'cloudhotspot'
def repo_name = 'todobackend'

node {
    checkout scm

    try {
        /*
        stage 'Run unit/integration tests'
        try { sh 'make test' } 
        catch(all) {
            step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
            error 'Test Failure'
        }
        
        stage 'Build application artefacts'
        sh 'make build'

        stage 'Create release environment and run acceptance tests'
        try { sh 'make release' }
        catch(all) {
            step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
            error 'Test Failure'
        }
        step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
        */

        // Requires Zentimestamp plugin for BUILD_TIMESTAMP variable
        stage 'Tag release image'
        def tags = [ '${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}' ]
        if (env.BRANCH_NAME == 'master') {
            tags << 'latest'
        }
        tags.each { tag -> 
            sh 'echo $BRANCH_NAME.$BUILD_ID'
            sh 'make tag ${tag}' 
        }

        stage 'Publish release image'
        def images = []
        tags.each { tag -> 
            images << docker.image('${org_name}/${repo_name}:${tag}')
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