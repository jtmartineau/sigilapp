from django.contrib import admin
from .models import Sigil

# Register your models here.
@admin.register(Sigil)
class SigilAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'incantation', 'is_burned', 'created_at', 'burned_at')
    list_filter = ('is_burned', 'created_at')
    search_fields = ('incantation', 'user__username')
    readonly_fields = ('created_at', 'burned_at')
