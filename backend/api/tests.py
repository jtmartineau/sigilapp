from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User

class IncantationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='testpassword')
        self.url = reverse('process_incantation')

    def test_process_incantation_unauthenticated(self):
        """Ensure unauthenticated users cannot access the endpoint."""
        data = {'incantation': 'abracadabra'}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_process_incantation_success(self):
        """Test valid incantation processing."""
        self.client.force_authenticate(user=self.user)
        # "Abracadabra" -> Vowels removed: B R C D B R -> Unique: B R C D
        data = {'incantation': 'Abracadabra'}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['consonants'], ['B', 'R', 'C', 'D'])

    def test_process_incantation_complex(self):
        """Test with spaces, numbers, and symbols."""
        self.client.force_authenticate(user=self.user)
        # "Hello, World! 123" -> H L L W R L D -> H L W R D
        data = {'incantation': 'Hello, World! 123'}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['consonants'], ['H', 'L', 'W', 'R', 'D'])

    def test_process_incantation_length_limit(self):
        """Test incantation length limit."""
        self.client.force_authenticate(user=self.user)
        long_text = 'a' * 129
        data = {'incantation': long_text}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_process_incantation_empty(self):
        """Test empty incantation."""
        self.client.force_authenticate(user=self.user)
        data = {'incantation': ''}
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

from django.core.files.uploadedfile import SimpleUploadedFile
from .models import Sigil

class SigilCreationTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='sigiluser', password='password')
        self.url = reverse('sigil_create')
        # Create a tiny 1x1 GIF to simulate an image upload
        self.small_gif = (
            b'\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\x05\x04\x04'
            b'\x00\x00\x00\x2c\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02\x44'
            b'\x01\x00\x3b'
        )

    def test_create_sigil_burned_with_location(self):
        """
        Test that uploading a sigil with is_burned=true and location data
        correctly saves all fields.
        """
        self.client.force_authenticate(user=self.user)
        
        image = SimpleUploadedFile("sigil.gif", self.small_gif, content_type="image/gif")
        
        data = {
            'incantation': 'Test Sigil',
            'image': image,
            'is_burned': 'true', # Simulate multipart string input
            'created_lat': '34.0522',
            'created_long': '-118.2437',
            'burned_lat': '34.0522',
            'burned_long': '-118.2437',
            'layout_type': 'Circle',
            'vertex_count': '-1',
            'letter_assignment': '[]'
        }
        
        response = self.client.post(self.url, data, format='multipart')
        
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        # Verify Database Integrity
        sigil = Sigil.objects.get(id=response.data['id'])
        
        self.assertTrue(sigil.is_burned)
        self.assertIsNotNone(sigil.burned_at)
        self.assertEqual(sigil.created_lat, 34.0522)
        self.assertEqual(sigil.created_long, -118.2437)
        self.assertEqual(sigil.burned_lat, 34.0522)
        self.assertEqual(sigil.burned_long, -118.2437)

    def test_create_sigil_not_burned(self):
        """
        Test that is_burned=false results in no burned_at timestamp.
        """
        self.client.force_authenticate(user=self.user)
        image = SimpleUploadedFile("sigil2.gif", self.small_gif, content_type="image/gif")
        
        data = {
            'incantation': 'Test Sigil 2',
            'image': image,
            'is_burned': 'false'
        }
        
        response = self.client.post(self.url, data, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        
        sigil = Sigil.objects.get(id=response.data['id'])
        self.assertFalse(sigil.is_burned)
        self.assertIsNone(sigil.burned_at)
