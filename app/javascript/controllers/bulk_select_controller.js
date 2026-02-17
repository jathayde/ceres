import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "toolbar", "count", "form"]

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => { checkbox.checked = checked })
    this.updateCount()
  }

  updateCount() {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount > 0) {
      this.toolbarTarget.classList.remove("hidden")
      this.toolbarTarget.classList.add("flex")
    } else {
      this.toolbarTarget.classList.add("hidden")
      this.toolbarTarget.classList.remove("flex")
    }

    this.countTarget.textContent = checkedCount

    // Sync select-all checkbox state
    this.selectAllTarget.checked = checkedCount === this.checkboxTargets.length && checkedCount > 0
    this.selectAllTarget.indeterminate = checkedCount > 0 && checkedCount < this.checkboxTargets.length
  }
}
