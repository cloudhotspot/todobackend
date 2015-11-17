// Groovy workflow script for Jenkins Workflow plugin
def src = 'https://github.com/cloudhotspot/todobackend.git'

node {
    git url: src

    stage 'Run unit/integration tests'
    try {
        sh 'make test'
    } catch(all) {
        step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
        error 'Test Failure'
    }
    
    stage 'Build application artefacts'
    sh 'make build'

    stage 'Create release environment and run acceptance tests'
    sh 'make release'

    stage 'Clean up'
    sh 'make clean'

    step([$class: 'JUnitResultArchiver', testResults: '**/src/*.xml'])
}