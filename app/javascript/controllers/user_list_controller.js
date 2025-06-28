import { Controller } from "@hotwired/stimulus"
import { get } from '@rails/request.js'

// Connects to data-controller="user-list"
export default class extends Controller {
  connect() {
    this.loadMore()
  }

  loadMore(){
    let count = this.element.dataset.counter
    count = parseInt(count) + 9
    this.element.dataset.counter = count
    get('/?limitCount=${count}', { responseKind: 'turbo-stream'} )
  }
}
