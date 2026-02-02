from rest_framework import serializers
from .models import Sigil

class SigilSerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(required=False)

    class Meta:
        model = Sigil
        fields = [
            'id', 'user', 'incantation', 'image', 'is_burned', 'created_at',
            'burned_at', 'created_lat', 'created_long', 'burned_lat', 'burned_long',
            'layout_type', 'vertex_count', 'letter_assignment'
        ]
        read_only_fields = ['user', 'created_at']
