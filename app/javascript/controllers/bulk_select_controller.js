import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "toolbar", "count", "form", "receiveForm"]

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

  submitReceive() {
    if (!this.hasReceiveFormTarget) return

    const form = this.receiveFormTarget
    form.querySelectorAll('input[type="hidden"]').forEach(el => el.remove())

    this.checkboxTargets.filter(cb => cb.checked).forEach(cb => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "buy_list_item_ids[]"
      input.value = cb.value
      form.appendChild(input)
    })

    form.submit()
  }
}
