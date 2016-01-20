#!/bin/bash
# Activate virtual environment
. /appenv/bin/activate

# Pull sensitive credentials from AWS credstash if CREDENTIAL_STORE is set
if [[ -n $CREDENTIAL_STORE ]]; then
  for item in "$(credstash -t $CREDENTIAL_STORE getall -f csv)"
  do
   read -a kv <<< "${item//,/ }"
   export ${kv[0]}=${kv[1]}
  done
fi

exec $@