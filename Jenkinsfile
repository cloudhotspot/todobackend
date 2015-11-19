// Groovy workflow script for Jenkins Multibranch Workflow plugin

node {
    checkout scm

    try {
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

        
        stage 'Tag release image'
        env.BUILD_TIMESTAMP = new Date().getTime()
        sh 'make tag $BRANCH_NAME.$BUILD_TIMESTAMP'

        if (isMaster()) {
            sh 'make tag latest'
        }

        stage 'Publish release image'
        def images = [docker.image('cloudhotspot/todobackend:${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}')]
        if (isMaster()) images << docker.image('cloudhotspot/todobackend')
        
        docker.withRegistry("https://registry.hub.docker.com", "docker-registry") {
          images.each { image -> image.push() }
        }
    }
    finally {
        stage 'Clean up'
        sh 'make clean'
    }
}

// Helper functions
def isMaster() {
    return env.BRANCH_NAME == 'master'
}