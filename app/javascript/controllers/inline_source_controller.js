import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sourceSelect", "formWrapper", "nameInput", "urlInput", "error",
                     "germinationHidden", "costDisplay", "costHidden"]
  static values = { url: String }

  connect() {
    // Sync germination rate display to hidden field on input
    const germDisplay = document.getElementById("germination_rate_display")
    if (germDisplay) {
      germDisplay.addEventListener("input", () => this.syncGerminationRate(germDisplay))
    }

    // Sync cost display to hidden field on input
    if (this.hasCostDisplayTarget) {
      this.costDisplayTarget.addEventListener("input", () => this.syncCost())
    }
  }

  toggleForm() {
    this.formWrapperTarget.classList.toggle("hidden")
    if (!this.formWrapperTarget.classList.contains("hidden")) {
      this.nameInputTarget.focus()
    }
  }

  async createSource() {
    const name = this.nameInputTarget.value.trim()
    if (!name) {
      this.showError("Name is required")
      return
    }

    const csrfToken = document.querySelector("[name='csrf-token']")?.content

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          seed_source: {
            name: name,
            url: this.urlInputTarget.value.trim()
          }
        })
      })

      if (response.ok) {
        const data = await response.json()
        const option = new Option(data.name, data.id, true, true)
        this.sourceSelectTarget.add(option)
        this.nameInputTarget.value = ""
        this.urlInputTarget.value = ""
        this.hideError()
        this.formWrapperTarget.classList.add("hidden")
      } else {
        const data = await response.json()
        this.showError(data.errors ? data.errors.join(", ") : "Failed to create source")
      }
    } catch (error) {
      this.showError("Network error. Please try again.")
    }
  }

  syncGerminationRate(displayField) {
    if (this.hasGerminationHiddenTarget) {
      const percent = parseFloat(displayField.value)
      this.germinationHiddenTarget.value = isNaN(percent) ? "" : (percent / 100).toFixed(4)
    }
  }

  syncCost() {
    if (this.hasCostHiddenTarget) {
      const dollars = parseFloat(this.costDisplayTarget.value)
      this.costHiddenTarget.value = isNaN(dollars) ? "" : Math.round(dollars * 100)
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }
}
