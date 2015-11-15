#!/bin/bash
# Activate virtual environment
. /appenv/bin/activate
pip install -r requirements_test.txt
exec $@