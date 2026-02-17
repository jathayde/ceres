import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["children"]
  static values = { expanded: Boolean }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (this.hasChildrenTarget) {
      this.childrenTarget.classList.toggle("hidden", !this.expandedValue)
    }
  }
}
