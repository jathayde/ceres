import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "message"]
  static values = { accept: String }

  validate() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const ext = file.name.split(".").pop().toLowerCase()
    if (ext !== "xlsx") {
      this.messageTarget.textContent = "Please select an .xlsx file"
      this.messageTarget.classList.add("text-red-500")
      this.messageTarget.classList.remove("text-gray-500")
      this.inputTarget.value = ""
    } else {
      this.messageTarget.textContent = `Selected: ${file.name} (${this.formatSize(file.size)})`
      this.messageTarget.classList.remove("text-red-500")
      this.messageTarget.classList.add("text-gray-500")
    }
  }

  formatSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
}
