
from setuptools import setup, find_packages

setup (
  name                 = "todobackend",
  version              = "0.1",
  description          = "Todo Backend Django REST service",
  packages             = find_packages(),
  scripts              = ["manage.py"],
  include_package_data = True,
  install_requires     = ["Django>=1.8.6",
                          "django-cors-headers>=1.1.0",
                          "djangorestframework>=3.3.1",
                          "MySQL-python>=1.2.5",
                          "uwsgi>=2.0"],
  extras_require       = {
                            "test": [
                              "django-nose>=1.4.2",
                              "nose>=1.3.7",
                              "pinocchio>=0.4.2",
                              "colorama>=0.3.3",
                              "coverage>=4.0.2",
                            ],
                         },
)