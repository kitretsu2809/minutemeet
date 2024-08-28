from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .serializers import *
from django.contrib.auth import authenticate, login , logout
import logging
from .models import User  # Import your custom User model
from django.views.decorators.csrf import csrf_exempt
from rest_framework.authtoken.models import Token
from meeting.models import User

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
        token, _ = Token.objects.get_or_create(user=user)
        logger.debug(f"Login successful for user: {username}")
        return Response({
            "message": "Login successful",
            "token": token.key
        }, status=status.HTTP_200_OK)
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
@csrf_exempt
@permission_classes([IsAuthenticated])
def update_location(request):
    # Deserialize and validate the incoming data
    serializer = LocationUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        # Extract latitude and longitude from validated data
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        # latitude = serializer.validated_data['latitude']
        # longitude = serializer.validated_data['longitude']
        
        # Update the authenticated user's location
        user = request.user
        user.latitude = latitude
        user.longitude = longitude
        user.save()  # Save the updated user object
        
        # Return a success response
        return Response({"message": "Location updated successfully"}, status=status.HTTP_200_OK)
    
    # If the data is invalid, return a 400 Bad Request with error details
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@csrf_exempt
# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
@api_view(['POST','PUT','PATCH'])
def create_group(request):
    print("Request Data:", request.data)  # Debugging print statement
    serializer = CreateGroupSerializer(data=request.data)
    
    if serializer.is_valid():
        group = serializer.save()
        
        # Prepare meeting data
        meeting_data = {
            "name": request.data.get('name'),  # Ensure 'name' is present in request data
            "user_phones": request.data.get('user_phones', [])  # Ensure 'user_phones' is present in request data
        }
        
        print("Meeting Data:", meeting_data)  # Debugging print statement
        
        meeting_serializer = CreateMeetingSerializer(data=meeting_data)
        if meeting_serializer.is_valid():
            meeting = meeting_serializer.save()
            
            return Response({
                "group_id": group.id,
                "group_name": group.name,
                "meeting_id": meeting.id,
                "meeting_name": meeting.name,
                "finalized_latitude": meeting.finalized_latitude,
                "finalized_longitude": meeting.finalized_longitude,
                "created_at": meeting.created_at
            }, status=status.HTTP_201_CREATED)
        
        # Return meeting errors if meeting creation fails
        return Response({
            "meeting_errors": meeting_serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Return group creation errors if group creation fails
    return Response({
        "group_errors": serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)

# @api_view(['POST','GET'])
# # @permission_classes([IsAuthenticated])
# def create_meeting(request):
#     serializer = CreateMeetingSerializer(data=request.data)
#     if serializer.is_valid():
#         meeting = serializer.save()
#         return Response({
#             "meeting_id": meeting.id,
#             "name": meeting.name,
#             "finalized_location": meeting.finalized_location,
#             "finalized_latitude": meeting.finalized_latitude,
#             "finalized_longitude": meeting.finalized_longitude,
#             "created_at": meeting.created_at
#         }, status=status.HTTP_201_CREATED)
#     return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
# @permission_classes([IsAuthenticated])
def user_meetings(request):
    logger.info(f"User {request.user.username} (ID: {request.user.id}) requesting meetings")
    logger.debug(f"User authenticated: {request.user.is_authenticated}")
    logger.debug(f"Request headers: {request.headers}")

    try:
        user = request.user
        user_groups = user.member_of_groups.all()
        logger.debug(f"User groups: {user_groups}")

        meetings = Meeting.objects.filter(group__in=user_groups)
        print(meetings)
        logger.debug(f"Found {meetings.count()} meetings for user")

        serializer = MeetingSerializer(meetings, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error in user_meetings view: {str(e)}")
        return Response({"error": "An unexpected error occurred"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

