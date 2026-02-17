import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemRow", "itemFields", "costDisplay", "costHidden"]
  static values = { plantsUrl: String }

  toggleSkip(event) {
    const checkbox = event.target
    const row = checkbox.closest("[data-receive-form-target='itemRow']")
    const fields = row.querySelector("[data-receive-form-target='itemFields']")

    if (checkbox.checked) {
      fields.classList.add("opacity-50", "pointer-events-none")
      fields.querySelectorAll("input, select").forEach(el => {
        el.removeAttribute("required")
      })
    } else {
      fields.classList.remove("opacity-50", "pointer-events-none")
    }
  }

  syncCost(event) {
    const display = event.target
    const row = display.closest("[data-receive-form-target='itemRow']")
    const hidden = row.querySelector("[data-receive-form-target='costHidden']")
    if (hidden) {
      const dollars = parseFloat(display.value)
      hidden.value = isNaN(dollars) ? "" : Math.round(dollars * 100)
    }
  }
}
