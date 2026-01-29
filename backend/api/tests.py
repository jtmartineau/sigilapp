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
