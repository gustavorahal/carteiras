import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["linhas", "linha"]

  adicionar() {
    const nova = this.linhaTargets[0].cloneNode(true)
    nova.querySelectorAll("input").forEach((input) => { input.value = "" })
    this.linhasTarget.appendChild(nova)
  }

  remover(event) {
    if (this.linhaTargets.length > 1) event.currentTarget.closest("[data-negociacoes-target=linha]").remove()
  }
}
