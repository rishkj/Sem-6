# Generated by Django 2.2.4 on 2020-04-13 13:32

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0004_item_gender'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='order',
            name='refund_granted',
        ),
        migrations.RemoveField(
            model_name='order',
            name='refund_requested',
        ),
        migrations.DeleteModel(
            name='Refund',
        ),
    ]
