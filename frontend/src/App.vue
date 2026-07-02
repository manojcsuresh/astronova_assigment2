<template>
  <div class="app">
    <!-- Toast Notifications -->
    <div class="toast-container">
      <TransitionGroup name="toast">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          :class="['toast', `toast-${toast.type}`]"
        >
          {{ toast.message }}
        </div>
      </TransitionGroup>
    </div>

    <!-- Header -->
    <header class="header">
      <div class="container header-inner">
        <div class="header-brand">
          <div class="logo">
            <svg viewBox="0 0 32 32" width="36" height="36">
              <defs>
                <linearGradient id="logoGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" style="stop-color:#7c3aed" />
                  <stop offset="100%" style="stop-color:#06b6d4" />
                </linearGradient>
              </defs>
              <circle cx="16" cy="16" r="14" fill="url(#logoGrad)" />
              <text x="16" y="21" text-anchor="middle" fill="white" font-size="14" font-weight="bold">A</text>
            </svg>
          </div>
          <div>
            <h1 class="header-title gradient-text">AstroNova</h1>
            <p class="header-subtitle">Book Management System</p>
          </div>
        </div>
        <div class="header-actions">
          <span class="badge badge-cyan">{{ books.length }} books</span>
          <button id="btn-add-book" class="btn btn-primary" @click="openCreateModal">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M8 3v10M3 8h10" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            Add Book
          </button>
        </div>
      </div>
    </header>

    <!-- Main Content -->
    <main class="main container">
      <!-- Loading State -->
      <div v-if="loading" class="loading-container">
        <div class="spinner"></div>
        <p>Loading your library...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="books.length === 0" class="empty-state">
        <div class="empty-state-icon">📚</div>
        <h3>Your library is empty</h3>
        <p>Start building your collection by adding your first book.</p>
        <button class="btn btn-primary" style="margin-top: 1.5rem;" @click="openCreateModal">
          Add Your First Book
        </button>
      </div>

      <!-- Book Grid -->
      <div v-else class="book-grid">
        <BookCard
          v-for="(book, index) in books"
          :key="book.id"
          :book="book"
          :style="{ animationDelay: `${index * 0.05}s` }"
          @edit="openEditModal"
          @delete="confirmDelete"
        />
      </div>
    </main>

    <!-- Create / Edit Modal -->
    <Transition name="modal">
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal-content">
          <h2 class="modal-title gradient-text">
            {{ editingBook ? 'Edit Book' : 'Add New Book' }}
          </h2>
          <BookForm
            :book="editingBook"
            :saving="saving"
            @submit="handleFormSubmit"
            @cancel="closeModal"
          />
        </div>
      </div>
    </Transition>

    <!-- Delete Confirmation Modal -->
    <Transition name="modal">
      <div v-if="showDeleteModal" class="modal-overlay" @click.self="cancelDelete">
        <div class="modal-content" style="max-width: 420px;">
          <h2 class="modal-title" style="color: #fca5a5;">Delete Book</h2>
          <p style="color: var(--text-secondary); margin-bottom: 0.5rem;">
            Are you sure you want to delete
            <strong style="color: var(--text-primary);">{{ deletingBook?.title }}</strong>?
          </p>
          <p style="color: var(--text-muted); font-size: 0.85rem;">
            This action cannot be undone.
          </p>
          <div class="modal-actions">
            <button id="btn-cancel-delete" class="btn btn-ghost" @click="cancelDelete">Cancel</button>
            <button id="btn-confirm-delete" class="btn btn-danger" @click="handleDelete" :disabled="saving">
              {{ saving ? 'Deleting...' : 'Delete' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Footer -->
    <footer class="footer">
      <div class="container">
        <p>AstroNova &copy; {{ new Date().getFullYear() }} — Built with Vue.js &amp; FastAPI</p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import BookCard from './components/BookCard.vue'
import BookForm from './components/BookForm.vue'
import bookService from './services/api.js'

// ─── State ─────────────────────────────────────────────────────
const books = ref([])
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const showDeleteModal = ref(false)
const editingBook = ref(null)
const deletingBook = ref(null)
const toasts = ref([])

// ─── Toast Notifications ──────────────────────────────────────
let toastId = 0
function showToast(message, type = 'success') {
  const id = ++toastId
  toasts.value.push({ id, message, type })
  setTimeout(() => {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }, 3500)
}

// ─── Data Loading ─────────────────────────────────────────────
async function fetchBooks() {
  try {
    books.value = await bookService.getBooks()
  } catch (err) {
    showToast('Failed to load books', 'error')
    console.error(err)
  } finally {
    loading.value = false
  }
}

// ─── Modal Handlers ───────────────────────────────────────────
function openCreateModal() {
  editingBook.value = null
  showModal.value = true
}

function openEditModal(book) {
  editingBook.value = { ...book }
  showModal.value = true
}

function closeModal() {
  showModal.value = false
  editingBook.value = null
}

// ─── Form Submit (Create / Update) ───────────────────────────
async function handleFormSubmit(formData) {
  saving.value = true
  try {
    if (editingBook.value) {
      const updated = await bookService.updateBook(editingBook.value.id, formData)
      const idx = books.value.findIndex(b => b.id === updated.id)
      if (idx !== -1) books.value[idx] = updated
      showToast('Book updated successfully')
    } else {
      const created = await bookService.createBook(formData)
      books.value.unshift(created)
      showToast('Book added to your library')
    }
    closeModal()
  } catch (err) {
    const msg = err.response?.data?.detail
    showToast(typeof msg === 'string' ? msg : 'Something went wrong', 'error')
    console.error(err)
  } finally {
    saving.value = false
  }
}

// ─── Delete Handlers ──────────────────────────────────────────
function confirmDelete(book) {
  deletingBook.value = book
  showDeleteModal.value = true
}

function cancelDelete() {
  showDeleteModal.value = false
  deletingBook.value = null
}

async function handleDelete() {
  if (!deletingBook.value) return
  saving.value = true
  try {
    await bookService.deleteBook(deletingBook.value.id)
    books.value = books.value.filter(b => b.id !== deletingBook.value.id)
    showToast('Book removed from library')
    cancelDelete()
  } catch (err) {
    showToast('Failed to delete book', 'error')
    console.error(err)
  } finally {
    saving.value = false
  }
}

// ─── Lifecycle ────────────────────────────────────────────────
onMounted(fetchBooks)
</script>

<style scoped>
/* ─── Header ────────────────────────────────────────────────── */
.header {
  padding: 1.5rem 0;
  border-bottom: 1px solid var(--border-subtle);
  background: rgba(10, 10, 26, 0.8);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 1rem;
}

.header-brand {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.logo {
  display: flex;
  animation: pulse-glow 3s ease-in-out infinite;
  border-radius: 50%;
}

.header-title {
  font-size: 1.75rem;
  line-height: 1;
}

.header-subtitle {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-top: 0.125rem;
  letter-spacing: 0.04em;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

/* ─── Main ──────────────────────────────────────────────────── */
.main {
  padding: 2.5rem 1.5rem;
  min-height: calc(100vh - 180px);
}

/* ─── Book Grid ─────────────────────────────────────────────── */
.book-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.25rem;
}

/* ─── Footer ────────────────────────────────────────────────── */
.footer {
  padding: 2rem 0;
  text-align: center;
  color: var(--text-muted);
  font-size: 0.8rem;
  border-top: 1px solid var(--border-subtle);
}

/* ─── Modal Transitions ─────────────────────────────────────── */
.modal-enter-active {
  animation: fadeIn 0.2s var(--ease-smooth);
}
.modal-leave-active {
  animation: fadeIn 0.15s var(--ease-smooth) reverse;
}

.modal-enter-active .modal-content {
  animation: scaleIn 0.3s var(--ease-spring);
}
.modal-leave-active .modal-content {
  animation: scaleIn 0.15s var(--ease-smooth) reverse;
}

/* ─── Toast Transitions ─────────────────────────────────────── */
.toast-enter-active {
  animation: slideInRight 0.4s var(--ease-spring);
}
.toast-leave-active {
  animation: slideOutRight 0.3s var(--ease-smooth) forwards;
}

/* ─── Responsive ────────────────────────────────────────────── */
@media (max-width: 640px) {
  .header-title {
    font-size: 1.35rem;
  }

  .book-grid {
    grid-template-columns: 1fr;
  }

  .header-inner {
    justify-content: center;
    text-align: center;
  }

  .header-actions {
    width: 100%;
    justify-content: center;
  }
}
</style>
