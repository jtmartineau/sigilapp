from django.contrib import admin
from django.utils.html import format_html
from .models import Sigil

# Register your models here.
@admin.register(Sigil)
class SigilAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'user', 'incantation', 
        'image_link',
        'is_burned', 
        'layout_type', 'letter_assignment',
        'created_lat', 'created_long', 
        'burned_at', 'burned_lat', 'burned_long'
    )
    list_filter = ('is_burned', 'created_at', 'layout_type')
    search_fields = ('incantation', 'user__username')
    readonly_fields = ('created_at', 'burned_at')

    def image_link(self, obj):
        if obj.image:
            return format_html('<a href="{}" target="_blank">{}</a>', obj.image.url, obj.image.name)
        return "No Image"
    image_link.short_description = 'Image Path'
