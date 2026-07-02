import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_URL || ''

const api = axios.create({
  baseURL: `${API_BASE}/api/books`,
  headers: { 'Content-Type': 'application/json' },
  timeout: 10000,
})

export default {
  /**
   * Fetch all books.
   * @returns {Promise<Array>}
   */
  async getBooks() {
    const { data } = await api.get('')
    return data
  },

  /**
   * Fetch a single book by ID.
   * @param {string} id
   * @returns {Promise<Object>}
   */
  async getBook(id) {
    const { data } = await api.get(`/${id}`)
    return data
  },

  /**
   * Create a new book.
   * @param {Object} book - { title, author, isbn?, publishedYear? }
   * @returns {Promise<Object>}
   */
  async createBook(book) {
    const { data } = await api.post('', book)
    return data
  },

  /**
   * Partially update a book.
   * @param {string} id
   * @param {Object} updates
   * @returns {Promise<Object>}
   */
  async updateBook(id, updates) {
    const { data } = await api.patch(`/${id}`, updates)
    return data
  },

  /**
   * Delete a book.
   * @param {string} id
   * @returns {Promise<void>}
   */
  async deleteBook(id) {
    await api.delete(`/${id}`)
  },
}
