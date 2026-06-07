from django.forms import ValidationError
from rest_framework import serializers
from .models import User, Group, Meeting
import googlemaps
from itertools import combinations

from django.conf import settings

# Initialize Google Maps client
gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)
def get_place(lat,long):
    result = gmaps.reverse_geocode((lat, long))
    if result:
        # Extract the formatted address from the first result
        address = result[0]['formatted_address']
        return address
    else:
        print("No results found.")
        return None

def get_lat_long(place_name):
    # Geocode the place name
    geocode_result = gmaps.geocode(place_name)

    if not geocode_result:
        return None

    # Extract the latitude and longitude
    location = geocode_result[0]['geometry']['location']
    latitude = location['lat']
    longitude = location['lng']

    return latitude, longitude

def find_nearest_places(locations, place_type='restaurant', radius=5000):
    places = []
    for location in locations:
        # Search for places near each location
        result = gmaps.places_nearby(location, radius=radius, type=place_type)
        places.extend(result['results'])
    
    # Remove duplicates by place_id
    unique_places = {place['place_id']: place for place in places}.values()
    return list(unique_places)

def calculate_distances(locations, places):
    distances = {}
    
    for place in places:
        place_location = (place['geometry']['location']['lat'], place['geometry']['location']['lng'])
        distances[place['place_id']] = sum(
            gmaps.distance_matrix(origins=loc, destinations=[place_location], mode='driving')['rows'][0]['elements'][0]['distance']['value']
            for loc in locations
        )
    
    return distances

def find_best_meeting_place(locations):
    if not locations:
        return None
    places = find_nearest_places(locations)
    if not places:
        return None
    distances = calculate_distances(locations, places)
    
    # Find the place with the minimum total distance
    best_place_id = min(distances, key=distances.get)
    best_place = next(place for place in places if place['place_id'] == best_place_id)
    
    return best_place

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'password', 'email', 'phone', 'location', 'latitude', 'longitude']
        extra_kwargs = {
            'password': {'write_only': True} 
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            phone=validated_data.get('phone', None),
            location=get_place(validated_data.get('latitude', None),validated_data.get('longitude', None)) if validated_data.get('latitude') and validated_data.get('longitude') else None,
            latitude=validated_data.get('latitude', None),
            longitude=validated_data.get('longitude', None)
        )
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

class LocationUpdateSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=True)
    longitude = serializers.FloatField(required=True)

class GroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ['name', 'members']

class CreateGroupSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    user_phones = serializers.ListField(
        child=serializers.CharField(max_length=20),
        max_length=4,  # Max 4 members
        min_length=1
    )

    def validate(self, data):
        name = data['name']
        user_phones = data['user_phones']
        
        # Check if all phone numbers belong to existing users
        users = User.objects.filter(phone__in=user_phones)
        if users.count() != len(set(user_phones)):
            raise serializers.ValidationError("One or more phone numbers are invalid.")
        
        return data

    def create(self, validated_data):
        name = validated_data['name']
        user_phones = validated_data['user_phones']
        
        # Create the group
        group = Group.objects.create(name=name)
        
        # Add users to the group
        users = User.objects.filter(phone__in=user_phones)
        
        # Include request user if they are missing
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # We convert to a list to add the current user if not already in the group
            user_list = list(users)
            if request.user not in user_list:
                user_list.append(request.user)
            group.members.set(user_list)
        else:
            group.members.set(users)
            
        group.save()
        
        return group

class CreateMeetingSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    group_id = serializers.IntegerField()

    def validate_group_id(self, value):
        if not Group.objects.filter(id=value).exists():
            raise serializers.ValidationError("Invalid group ID.")
        return value

    def create(self, validated_data):
        group = Group.objects.get(id=validated_data['group_id'])
        name = validated_data['name']

        users = group.members.all()
        
        latitudes = []
        longitudes = []
        for user in users:
            if user.latitude and user.longitude:
                latitudes.append(user.latitude)
                longitudes.append(user.longitude)
        
        locations = list(zip(latitudes, longitudes))

        lat = None
        lng = None
        if locations:
            best_meeting_place = find_best_meeting_place(locations)
            if best_meeting_place:
                lat = best_meeting_place['geometry']['location']['lat']
                lng = best_meeting_place['geometry']['location']['lng']
        
        meeting = Meeting.objects.create(
            group=group,
            name=name,
            finalized_latitude=lat,
            finalized_longitude=lng
        )

        return meeting
    
class MeetingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Meeting
        fields = ['id', 'name', 'date', 'finalized_location', 'finalized_latitude', 'finalized_longitude', 'created_at']