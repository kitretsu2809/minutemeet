from rest_framework import serializers
from .models import User, Group, Meeting

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'password', 'email', 'phone', 'location', 'latitude', 'longitude']
        extra_kwargs = {
            'password': {'write_only': True}  # Ensures that password is write-only
        }

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            phone=validated_data.get('phone', None),
            location=validated_data.get('location', None),
            latitude=validated_data.get('latitude', None),
            longitude=validated_data.get('longitude', None)
        )
        return user

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

class LocationUpdateSerializer(serializers.Serializer):
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)

class GroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ['id', 'name', 'members']

class CreateGroupSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    user_phones = serializers.ListField(
        child=serializers.CharField(max_length=20),
        max_length=4,  # Max 4 members
        min_length=1
    )

    def validate_user_phones(self, value):
        if len(value) > 4:
            raise serializers.ValidationError("A group can have a maximum of 4 members.")
        return value

    def validate(self, data):
        name = data['name']
        user_phones = data['user_phones']
        
        # Check for duplicate group names
        if Group.objects.filter(name=name).exists():
            raise serializers.ValidationError("A group with this name already exists.")
        
        # Check if all phone numbers belong to existing users
        users = User.objects.filter(phone__in=user_phones)
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