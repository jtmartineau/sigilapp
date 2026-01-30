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
        # If it's being burned immediately on creation
        is_burned = self.request.data.get('is_burned', 'false').lower() == 'true'
        burned_at = timezone.now() if is_burned else None
        
        serializer.save(
            user=self.request.user,
            burned_at=burned_at
        )
