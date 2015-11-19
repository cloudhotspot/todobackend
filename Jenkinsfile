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
        sh 'make tag $BRANCH_NAME.$BUILD_ID'
        if (isMaster()) {
            sh 'make tag latest'
        }

        stage 'Publish'
        sh 'make publish'
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