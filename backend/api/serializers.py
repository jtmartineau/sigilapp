from rest_framework import serializers
from .models import Sigil

class SigilSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sigil
        fields = [
            'id', 'user', 'incantation', 'image', 'is_burned', 'created_at',
            'burned_at', 'created_lat', 'created_long', 'burned_lat', 'burned_long'
        ]
        read_only_fields = ['user', 'created_at']
