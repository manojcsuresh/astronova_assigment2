<template>
  <form class="book-form" @submit.prevent="handleSubmit" id="book-form">
    <div class="form-grid">
      <div class="form-group form-full">
        <label class="form-label" for="input-title">Title *</label>
        <input
          id="input-title"
          v-model="form.title"
          class="form-input"
          type="text"
          placeholder="e.g. The Great Gatsby"
          required
          maxlength="300"
        />
      </div>

      <div class="form-group form-full">
        <label class="form-label" for="input-author">Author *</label>
        <input
          id="input-author"
          v-model="form.author"
          class="form-input"
          type="text"
          placeholder="e.g. F. Scott Fitzgerald"
          required
          maxlength="200"
        />
      </div>

      <div class="form-group">
        <label class="form-label" for="input-isbn">ISBN</label>
        <input
          id="input-isbn"
          v-model="form.isbn"
          class="form-input"
          type="text"
          placeholder="e.g. 978-0743273565"
          maxlength="20"
        />
      </div>

      <div class="form-group">
        <label class="form-label" for="input-year">Published Year</label>
        <input
          id="input-year"
          v-model.number="form.publishedYear"
          class="form-input"
          type="number"
          placeholder="e.g. 1925"
          min="1000"
          max="2100"
        />
      </div>
    </div>

    <div class="modal-actions">
      <button type="button" id="btn-cancel-form" class="btn btn-ghost" @click="$emit('cancel')">
        Cancel
      </button>
      <button type="submit" id="btn-submit-form" class="btn btn-primary" :disabled="saving || !isValid">
        {{ saving ? 'Saving...' : (book ? 'Update Book' : 'Add Book') }}
      </button>
    </div>
  </form>
</template>

<script setup>
import { reactive, computed, watchEffect } from 'vue'

const props = defineProps({
  book: { type: Object, default: null },
  saving: { type: Boolean, default: false },
})

const emit = defineEmits(['submit', 'cancel'])

const form = reactive({
  title: '',
  author: '',
  isbn: '',
  publishedYear: null,
})

// Pre-fill form when editing
watchEffect(() => {
  if (props.book) {
    form.title = props.book.title || ''
    form.author = props.book.author || ''
    form.isbn = props.book.isbn || ''
    form.publishedYear = props.book.publishedYear || null
  } else {
    form.title = ''
    form.author = ''
    form.isbn = ''
    form.publishedYear = null
  }
})

const isValid = computed(() => {
  return form.title.trim().length > 0 && form.author.trim().length > 0
})

function handleSubmit() {
  if (!isValid.value) return

  const payload = {
    title: form.title.trim(),
    author: form.author.trim(),
  }

  // Only include optional fields if they have values
  if (form.isbn && form.isbn.trim()) {
    payload.isbn = form.isbn.trim()
  }
  if (form.publishedYear) {
    payload.publishedYear = form.publishedYear
  }

  emit('submit', payload)
}
</script>

<style scoped>
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-full {
  grid-column: 1 / -1;
}

@media (max-width: 480px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
