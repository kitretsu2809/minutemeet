from django.urls import path
from .views import *

urlpatterns = [
    path('register/', register, name='register'),
    path('login/', login_view, name='login'),
    path('logout/', logout_view, name='logout'),
    path('home/', home_view, name='home'),
    path('update_location/', update_location, name='update_location'),
    path('create-group/', create_group, name='create_group'),
    path('user/meetings', user_meetings, name='user_meetings')  

]

