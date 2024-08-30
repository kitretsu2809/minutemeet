from django.forms import ValidationError
from rest_framework import serializers
from .models import User, Group, Meeting
import googlemaps
from itertools import combinations

# Initialize Google Maps client
gmaps = googlemaps.Client(key='AIzaSyC9OK4cKIweM7ph1Tnm3yWpfWGibDFstcg')
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
    return unique_places

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
    places = find_nearest_places(locations)
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
            location=get_place(validated_data.get('latitude', None),validated_data.get('longitude', None)),
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

        # Ensure at least one phone number belongs to the logged-in user
        

    # def validate_user_phones(self,data):
    #     if len(data) > 4:
    #         raise serializers.ValidationError("A group can have a maximum of 4 members.")
    #     user = self.context['request'].user
    #     if not user:
    #         raise ValidationError("User is not authenticated")

    #     user_phone = user.phone  # Assuming the `phone` field stores the user's phone number

    #     if user_phone not in user_phones:
    #         raise ValidationError("At least one phone number must belong to the logged-in user")

    #     return user_phones

    def validate(self, data):
        name = data['name']
        user_phones = data['user_phones']
        
        # Check for duplicate group names
        if Group.objects.filter(name=name).exists():
            raise serializers.ValidationError("A group with this name already exists.")
        
        # Check if all phone numbers belong to existing users
        users = User.objects.filter(phone__in=user_phones)
        print("Fuck")
        print(users)
        if users.count() != len(user_phones):
            raise serializers.ValidationError("One or more phone numbers are invalid.")
        
        return data

    def create(self, validated_data):
        name = validated_data['name']
        user_phones = validated_data['user_phones']
        
        # Create the group
        group = Group.objects.create(name=name)
        
        # Add users to the group
        users = User.objects.filter(phone__in=user_phones)
        group.members.set(users)
        group.save()
        
        return group
class CreateMeetingSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    user_phones = serializers.ListField(
        child=serializers.CharField(max_length=20),
        max_length=4,
        min_length=2
    )

    def validate_user_phones(self, value):
        if len(value) > 4:
            raise serializers.ValidationError("A group can have a maximum of 4 members.")
        return value
    
    

    def create(self, validated_data):
        group = Group.objects.get(name=validated_data['name'])
        print(group)
        name = validated_data['name']
        user_phones = validated_data['user_phones']
        print(user_phones)
        print(name)

        users = User.objects.filter(phone__in=user_phones)
        print("FuckYou")
        print(users)
        
        if users.count() != len(user_phones):
            print(users.count(), len(user_phones))
            raise serializers.ValidationError("One or more phone numbers are invalid or users not in group.")

        # Calculate the optimal location
        # avg_latitude = sum(user.latitude for user in users) / len(users)
        # avg_longitude = sum(user.longitude for user in users) / len(users)
        latitudes = []
        longitudes = []
        for user in users:
            latitudes.append(user.latitude)
            longitudes.append(user.longitude)
        locations = list(zip(latitudes, longitudes))

        best_meeting_place = find_best_meeting_place(locations)
        print(best_meeting_place)
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