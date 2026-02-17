import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoryField", "subcategoryField"]

  close() {
    this.element.classList.add("hidden")
  }

  open() {
    this.element.classList.remove("hidden")
  }

  toggleFields(event) {
    const value = event.target.value
    if (this.hasCategoryFieldTarget && this.hasSubcategoryFieldTarget) {
      if (value === "category") {
        this.categoryFieldTarget.classList.remove("hidden")
        this.subcategoryFieldTarget.classList.add("hidden")
      } else {
        this.categoryFieldTarget.classList.add("hidden")
        this.subcategoryFieldTarget.classList.remove("hidden")
      }
    }
  }
}
