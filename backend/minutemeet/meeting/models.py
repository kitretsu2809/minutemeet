from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.crypto import get_random_string
import random
import string
class User(AbstractUser):
    phone = models.CharField(max_length=20, null=True, blank=True)
    email = models.EmailField(unique=True)
    location = models.CharField(max_length=255, null=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    groups = models.ManyToManyField(
        'Group',  # Reference to the Group model
        related_name='users',  # Updated related_name to avoid conflict
        blank=True,
        help_text='The groups this user belongs to.',
        verbose_name='groups'
    )

    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='custom_user_permission_set',
        blank=True,
        help_text='Specific permissions for this user.',
        verbose_name='user permissions'
    )

    def __str__(self):
        return self.username

# models.py
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Group(models.Model):
    name = models.CharField(max_length=255)
    members = models.ManyToManyField(User, related_name='member_of_groups')  # Updated related_name

    def __str__(self):
        return self.name

    
class Meeting(models.Model):
    group = models.ForeignKey(Group, on_delete=models.CASCADE, related_name='meetings')
    name = models.CharField(max_length=255)
    date = models.DateTimeField(null=True, blank=True)
    finalized_location = models.CharField(max_length=255, null=True, blank=True)
    finalized_latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    finalized_longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name
    
