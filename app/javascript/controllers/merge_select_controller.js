import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "count", "mergeButton"]

  updateSelection() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const count = checked.length

    if (count >= 2) {
      this.toolbarTarget.style.display = "flex"
      this.countTarget.textContent = `${count} selected`
    } else {
      this.toolbarTarget.style.display = "none"
    }

    this.selectAllTarget.checked = count === this.checkboxTargets.length
    this.selectAllTarget.indeterminate = count > 0 && count < this.checkboxTargets.length
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateSelection()
  }

  validateSelection(event) {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    if (checked.length < 2) {
      event.preventDefault()
      alert("Select at least two seed sources to merge.")
    }
  }
}
