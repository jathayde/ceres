import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sourceSelect"]

  selectSource() {
    const sourceId = this.sourceSelectTarget.value
    const url = new URL(window.location.href)

    if (sourceId) {
      url.searchParams.set("seed_source_id", sourceId)
    } else {
      url.searchParams.delete("seed_source_id")
    }

    const frame = document.querySelector("turbo-frame#inventory_content")
    if (frame) {
      frame.src = url.toString()
    }

    history.pushState({}, "", url.toString())
  }
}
