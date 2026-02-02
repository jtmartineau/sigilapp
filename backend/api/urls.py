from django.urls import path
from .views import hello_world, process_incantation, SigilListCreateView, BurnSigilView

urlpatterns = [
    path('hello/', hello_world, name='hello_world'),
    path('process-incantation/', process_incantation, name='process_incantation'),
    path('sigils/', SigilListCreateView.as_view(), name='sigil_list_create'),
    path('sigils/<uuid:pk>/burn/', BurnSigilView.as_view(), name='sigil_burn'),
]
