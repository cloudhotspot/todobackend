from base import *
import os

# Disable debug

DEBUG = False


# Must be explicitly specified with Debug is disabled

ALLOWED_HOSTS = ['*']


# Database
# https://docs.djangoproject.com/en/1.8/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('MYSQL_DATABASE','todobackend'),
        'USER': os.environ.get('MYSQL_USER','todo'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD','password'),
        'HOST': os.environ.get('MYSQL_HOST','localhost'),
        'PORT': os.environ.get('MYSQL_PORT','3306'),
    }
}

STATIC_ROOT = os.environ.get('STATIC_ROOT','/var/www/todobackend/static')
MEDIA_ROOT = os.environ.get('MEDIA_ROOT','/var/www/todobackend/media')