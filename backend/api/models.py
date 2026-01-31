from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
import uuid

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    # Unique ID for anonymous analysis
    analytics_id = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)

    def __str__(self):
        return f"Profile for {self.user.username}"

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    try:
        instance.profile.save()
    except Exception:
        Profile.objects.create(user=instance)

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

    # Layout Data
    layout_type = models.CharField(max_length=50, default='Unknown') # Circle or Polygon
    vertex_count = models.IntegerField(default=-1) # -1 for Circle, else N
    letter_assignment = models.TextField(default='[]') # Python list of tuples string representation

    def __str__(self):
        return f"Sigil by {self.user.username} at {self.created_at}"
