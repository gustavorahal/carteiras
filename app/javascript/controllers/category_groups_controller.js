import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row"]

  toggle(event) {
    const button = event.currentTarget
    const category = button.dataset.category
    const collapse = button.getAttribute("aria-expanded") === "true"

    button.setAttribute("aria-expanded", String(!collapse))
    this.rowTargets
      .filter((row) => row.dataset.category === category)
      .forEach((row) => { row.hidden = collapse })
  }
}
