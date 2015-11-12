from django.core.urlresolvers import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from todo.models import TodoItem

# Create your tests here.
class TodoItemTests(APITestCase):
  def test_create_todoitem(self):
    """
    Ensure we can create a new todo item
    """
    url = reverse('todoitem-list')
    data = {'title': 'Walk the dog'}
    response = self.client.post(url, data, format='json')
    self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    self.assertEqual(TodoItem.objects.count(), 1)
    self.assertEqual(TodoItem.objects.get().title, 'Walk the dog')