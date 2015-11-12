from todo.models import TodoItem
from todo.serializers import TodoItemSerializer
from rest_framework import viewsets
from rest_framework.reverse import reverse

class TodoItemViewSet(viewsets.ModelViewSet):
  queryset = TodoItem.objects.all()
  serializer_class = TodoItemSerializer

  def perform_create(self, serializer):
    # Save instance to get primary key and then update URL
    instance = serializer.save()
    instance.url = reverse('todoitem-detail', args=[instance.pk], request=self.request)
    instance.save()