from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework import generics
from .models import Sigil
from .serializers import SigilSerializer
import re

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def hello_world(request):
    return Response({"message": "Hello from Django!"})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def process_incantation(request):
    """
    Process an incantation:
    1. Remove vowels.
    2. Keep unique consonants in order of appearance.
    """
    incantation = request.data.get('incantation', '')
    if not incantation:
        return Response(
            {"error": "Incantation text is required."}, 
            status=status.HTTP_400_BAD_REQUEST
        )

    # limit to 128 characters as per requirements
    if len(incantation) > 128:
        return Response(
            {"error": "Incantation cannot exceed 128 characters."},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Normalize to uppercase
    text = incantation.upper()
    
    # Define vowels and consonants
    vowels = set("AEIOU")
    
    # Filter for only letters first
    letters = [char for char in text if char.isalpha()]
    
    # Filter out vowels
    consonants = [char for char in letters if char not in vowels]
    
    # Remove duplicates while preserving order
    # dict.fromkeys() relies on insertion order (Python 3.7+)
    unique_consonants = list(dict.fromkeys(consonants))
    
    return Response({"consonants": unique_consonants})

from django.utils import timezone

class SigilCreateView(generics.CreateAPIView):
    queryset = Sigil.objects.all()
    serializer_class = SigilSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        # Debug: Print all incoming data keys to see what's actually arriving
        print(f"DEBUG: Incoming Keys: {self.request.data.keys()}")
        print(f"DEBUG: Incoming Data: {self.request.data}")

        # Helper to safely parse floats from multipart strings
        def parse_float(key):
            val = self.request.data.get(key)
            if val in [None, '', 'null']:
                return None
            try:
                return float(val)
            except (ValueError, TypeError):
                print(f"DEBUG: Failed to parse float for {key}: {val}")
                return None

        # 1. Handle is_burned (Fallback logic)
        is_burned = serializer.validated_data.get('is_burned')
        if is_burned is None:
             raw_val = self.request.data.get('is_burned')
             if raw_val and str(raw_val).lower() in ['true', '1', 'on']:
                 is_burned = True
             else:
                 is_burned = False
        
        # 2. Handle Location Fields (Manual Extraction)
        # We manually extract these because the serializer might be dropping them
        created_lat = parse_float('created_lat')
        created_long = parse_float('created_long')
        burned_lat = parse_float('burned_lat')
        burned_long = parse_float('burned_long')

        # 3. Calculate derived fields
        burned_at = timezone.now() if is_burned else None
        
        print(f"DEBUG: Saving - Burned: {is_burned}, C_Lat: {created_lat}, B_Lat: {burned_lat}")

        # Save the instance with explicit values
        serializer.save(
            user=self.request.user, 
            burned_at=burned_at,
            is_burned=is_burned,
            created_lat=created_lat,
            created_long=created_long,
            burned_lat=burned_lat,
            burned_long=burned_long
        )
