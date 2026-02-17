import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["plantType", "category", "subcategory", "subcategoryWrapper"]
  static values = {
    categoriesUrl: String,
    subcategoriesUrl: String,
    selectedCategory: Number,
    selectedSubcategory: Number
  }

  typeChanged() {
    const typeId = this.plantTypeTarget.value
    this.clearSelect(this.categoryTarget, "Select a category...")
    this.hideSubcategory()

    if (!typeId) return

    fetch(`${this.categoriesUrlValue}?plant_type_id=${typeId}`)
      .then(response => response.json())
      .then(categories => {
        categories.forEach(cat => {
          const option = new Option(cat.name, cat.id)
          this.categoryTarget.add(option)
        })
      })
  }

  categoryChanged() {
    const categoryId = this.categoryTarget.value
    this.hideSubcategory()

    if (!categoryId) return

    fetch(`${this.subcategoriesUrlValue}?plant_category_id=${categoryId}`)
      .then(response => response.json())
      .then(subcategories => {
        if (subcategories.length > 0) {
          this.clearSelect(this.subcategoryTarget, "None")
          subcategories.forEach(sub => {
            const option = new Option(sub.name, sub.id)
            this.subcategoryTarget.add(option)
          })
          this.subcategoryWrapperTarget.classList.remove("hidden")
        }
      })
  }

  clearSelect(select, placeholder) {
    select.innerHTML = ""
    const blank = new Option(placeholder, "")
    select.add(blank)
  }

  hideSubcategory() {
    if (this.hasSubcategoryWrapperTarget) {
      this.subcategoryWrapperTarget.classList.add("hidden")
      this.clearSelect(this.subcategoryTarget, "None")
    }
  }
}
