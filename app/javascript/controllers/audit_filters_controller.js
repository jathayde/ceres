import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { baseUrl: String, param: String, clear: String }

  selectFilter() {
    const url = new URL(window.location.href)
    const value = this.element.querySelector("select, input")?.value

    if (value) {
      url.searchParams.set(this.paramValue, value)
    } else {
      url.searchParams.delete(this.paramValue)
    }

    // Clear dependent filter if specified
    if (this.hasClearValue && this.clearValue) {
      url.searchParams.delete(this.clearValue)
    }

    window.location.href = url.toString()
  }
}
