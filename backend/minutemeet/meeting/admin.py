from django.contrib import admin
from meeting.models import *
# Register your models here.

admin.site.register(User)
admin.site.register(Meeting)
admin.site.register(Group)

