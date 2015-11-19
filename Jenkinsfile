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
        env.TEST = "${env.BRANCH_NAME}.${env.BUILD_TIMESTAMP}" 
        sh 'echo $TEST'
        sh 'echo $BRANCH_NAME.$BUILD_TIMESTAMP'
        def tags = [ env.BRANCH_NAME + '.' + env.BUILD_TIMESTAMP ]
        if (env.BRANCH_NAME == 'master') {
            tags << 'latest'
        }
        tags.each { tag -> 
            sh 'make tag ${tag}' 
        }

    }
    finally {
        stage 'Clean up'
        sh 'make clean'
    }
}