# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='TodoItem',
            fields=[
                ('id', models.AutoField(verbose_name='ID', serialize=False, auto_created=True, primary_key=True)),
                ('title', models.CharField(max_length=256, null=True, blank=True)),
                ('completed', models.NullBooleanField(default=False)),
                ('url', models.CharField(max_length=256, null=True, blank=True)),
                ('order', models.IntegerField(null=True, blank=True)),
            ],
        ),
    ]
