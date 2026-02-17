import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateCategories(event) {
    const selectedType = event.target.value
    const categorySelect = this.element.querySelector("[name='mapped_category_name']")

    if (!categorySelect) return

    Array.from(categorySelect.options).forEach(option => {
      const plantType = option.dataset.plantType
      if (plantType) {
        option.hidden = plantType !== selectedType
        if (option.hidden && option.selected) {
          option.selected = false
        }
      }
    })

    // Select first visible option
    const firstVisible = Array.from(categorySelect.options).find(o => !o.hidden)
    if (firstVisible) firstVisible.selected = true
  }
}
