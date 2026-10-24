from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers


class UserSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    confirm_password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'confirm_password']

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with that email already exists.")
        return value

    def validate(self, data):
        if data['password'] != data['confirm_password']:
            raise serializers.ValidationError(
                {'confirm_password': 'Passwords do not match.'}
            )
        try:
            validate_password(
                data['password'],
                user=User(username=data.get('username', ''), email=data.get('email', '')),
            )
        except DjangoValidationError as e:
            raise serializers.ValidationError({'password': list(e.messages)})
        return data

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        return User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
        )
# from django.contrib.auth.models import User
# from rest_framework import serializers


# class UserSerializer(serializers.ModelSerializer):

#     confirm_password = serializers.CharField(write_only=True,style={'input_type':'password'})
#     password = serializers.CharField(write_only=True, min_length=8,style={'input_type':'password'})

#     class Meta:
#         model = User
#         fields = [
#             'username',
#             'email',
#             'password',
#             'confirm_password',
#         ]

#     def validate(self, data):
#         if data['password'] != data['confirm_password']:
#             raise serializers.ValidationError(
#                 {'confirm_password': 'Passwords do not match.'}
#             )
#         return data

#     def create(self, validated_data):
#         validated_data.pop('confirm_password')

#         return User.objects.create_user(
#             username=validated_data['username'],
#             email=validated_data['email'],
#             password=validated_data['password'],
#         )

# from django.contrib.auth.models import User
# from rest_framework import serializers

# class UserSerializer(serializers.ModelSerializer):
#     password=serializers.CharField(write_only=True,min_length=8,style={'input_type':'password'})
#     class Meta:
#         model=User
#         fields=['username','email','password','confirm_password']

#     def create(self, validated_data):
#         # User.objects.create =save the password in a plain text
#         # User.objects.create_user=automatically chash the password
#         user=User.objects.create_user(
#             validated_data['username'],
#             validated_data['email'],
#             validated_data['password'],
#             validated_data['confirm_password']
#         )

#         # user=User.objects.create_user(**validated_data)
#         return user