<template>
  <div class="card book-card" :id="`book-${book.id}`">
    <div class="book-card-header">
      <div class="book-color-bar"></div>
      <div class="book-info">
        <h3 class="book-title">{{ book.title }}</h3>
        <p class="book-author">by {{ book.author }}</p>
      </div>
    </div>

    <div class="book-meta">
      <span v-if="book.isbn" class="badge badge-purple" title="ISBN">
        {{ book.isbn }}
      </span>
      <span v-if="book.publishedYear" class="badge badge-cyan">
        {{ book.publishedYear }}
      </span>
    </div>

    <div class="book-actions">
      <button
        :id="`btn-edit-${book.id}`"
        class="btn btn-ghost btn-sm"
        @click="$emit('edit', book)"
        title="Edit book"
      >
        <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
          <path d="M11.5 1.5l3 3L5 14H2v-3L11.5 1.5z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Edit
      </button>
      <button
        :id="`btn-delete-${book.id}`"
        class="btn btn-ghost btn-sm btn-delete"
        @click="$emit('delete', book)"
        title="Delete book"
      >
        <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
          <path d="M2 4h12M5 4V2h6v2M6 7v5M10 7v5M3 4l1 10h8l1-10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        Delete
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  book: {
    type: Object,
    required: true,
  },
})

defineEmits(['edit', 'delete'])
</script>

<style scoped>
.book-card {
  padding: 0;
  overflow: hidden;
  animation: fadeInUp 0.5s var(--ease-smooth) both;
  display: flex;
  flex-direction: column;
}

.book-card-header {
  position: relative;
  padding: 1.25rem 1.25rem 0.75rem;
}

.book-color-bar {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: var(--gradient-accent);
  opacity: 0;
  transition: opacity var(--transition-normal);
}

.book-card:hover .book-color-bar {
  opacity: 1;
}

.book-title {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.35;
  margin-bottom: 0.25rem;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.book-author {
  font-size: 0.85rem;
  color: var(--text-secondary);
  font-weight: 400;
}

.book-meta {
  padding: 0 1.25rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  flex-grow: 1;
}

.book-actions {
  display: flex;
  gap: 0.5rem;
  padding: 1rem 1.25rem;
  border-top: 1px solid var(--border-subtle);
  margin-top: 1rem;
}

.btn-delete:hover {
  color: #fca5a5 !important;
  border-color: rgba(239, 68, 68, 0.3) !important;
  background: rgba(239, 68, 68, 0.08) !important;
}
</style>
