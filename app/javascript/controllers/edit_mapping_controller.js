import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { rowId: Number }

  toggle() {
    const form = document.getElementById(`edit_form_${this.rowIdValue}`)
    if (form) {
      form.classList.toggle("hidden")
    }
  }
}
