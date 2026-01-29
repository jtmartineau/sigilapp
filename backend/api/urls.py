from django.urls import path
from .views import hello_world, process_incantation

urlpatterns = [
    path('hello/', hello_world, name='hello_world'),
    path('process-incantation/', process_incantation, name='process_incantation'),
]
