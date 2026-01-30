from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class Sigil(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    incantation = models.TextField()
    image = models.ImageField(upload_to='sigils/')
    is_burned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    burned_at = models.DateTimeField(null=True, blank=True)
    
    # Location Data
    created_lat = models.FloatField(null=True, blank=True)
    created_long = models.FloatField(null=True, blank=True)
    burned_lat = models.FloatField(null=True, blank=True)
    burned_long = models.FloatField(null=True, blank=True)

    def __str__(self):
        return f"Sigil by {self.user.username} at {self.created_at}"
