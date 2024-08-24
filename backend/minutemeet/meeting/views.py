from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .serializers import *
from django.contrib.auth import authenticate, login , logout
import logging
from .models import User  # Import your custom User model

logger = logging.getLogger(__name__)
@api_view(['POST'])
def register(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def login_view(request):
    logger.debug(f"Request data: {request.data}")
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    
    username = serializer.validated_data['username']
    password = serializer.validated_data['password']
    
    logger.debug(f"Authenticating user: {username}")
    user = authenticate(request, username=username, password=password)
    
    if user is not None:
        login(request, user)
        logger.debug(f"Login successful for user: {username}")
        return Response({"message": "Login successful"}, status=status.HTTP_200_OK)
    else:
        logger.debug(f"Invalid credentials for user: {username}")
        return Response({"error": "Invalid username or password"}, status=status.HTTP_400_BAD_REQUEST)
    
@api_view(['POST'])
def logout_view(request):
    # Log out the user
    logout(request)
    # Return a response indicating the user has been logged out
    return Response({"message": "Logged out successfully"}, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def home_view(request):
    user = request.user
    
    user_data = {
        "name": user.username,
        "email": user.email,
        "location": user.location,
        "latitude": user.latitude,
        "longitude": user.longitude,
    }
    
    return Response(user_data, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_location(request):
    serializer = LocationUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        latitude = serializer.validated_data['latitude']
        longitude = serializer.validated_data['longitude']
        
        # Update the authenticated user's location
        user = request.user
        user.latitude = latitude
        user.longitude = longitude
        user.save()
        
        return Response({"message": "Location updated successfully"}, status=status.HTTP_200_OK)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def create_group(request):
    serializer = CreateGroupSerializer(data=request.data)
    if serializer.is_valid():
        group = serializer.save()
        return Response({"group_id": group.id, "name": group.name}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)