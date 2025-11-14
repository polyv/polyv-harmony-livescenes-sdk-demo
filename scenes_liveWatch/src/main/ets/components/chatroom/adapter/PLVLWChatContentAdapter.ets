import { PLVBaseIdEvent } from '@polyvharmony/live-scenes-sdk';
import { derivedStateOf, extendArray, mutableStateOf, State } from '@polyvharmony/media-player-sdk';

export class PLVLWChatContentAdapter implements IDataSource {
  private adapterListeners: DataChangeListener[] = []
  private readonly chatMessages = mutableStateOf<PLVBaseIdEvent[]>([])
  private readonly messageFilter = mutableStateOf<(message: PLVBaseIdEvent) => boolean>(() => true)
  private readonly showMessages = derivedStateOf(() => {
    const allMessages = this.chatMessages.value ?? []
    const filter = this.messageFilter.value ?? (() => true)
    return allMessages.filter(filter)
  })

  constructor() {
    this.showMessages.observe(() => {
      this.adapterListeners.forEach(listener => {
        listener.onDataReloaded()
      })
    })
  }

  totalCount(): number {
    return this.showMessages.value?.length ?? 0;
  }

  getData(index: number): PLVBaseIdEvent | undefined {
    return this.showMessages.value?.[index] ?? undefined
  }

  getChatMessages(): PLVBaseIdEvent[] {
    return this.chatMessages.value ?? []
  }

  getChatMessagesState(): State<PLVBaseIdEvent[]> {
    return this.chatMessages
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.adapterListeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    extendArray(this.adapterListeners).remove_ext(listener)
  }

  appendFirst(messages: PLVBaseIdEvent[]) {
    const oldMessages = this.chatMessages.value ?? []
    const newMessages = [...messages, ...oldMessages]
    this.chatMessages.value = newMessages
  }

  appendLast(messages: PLVBaseIdEvent[]) {
    const oldMessages = this.chatMessages.value ?? []
    const newMessages = [...oldMessages, ...messages]
    this.chatMessages.value = newMessages
  }

  dropFirst(count: number) {
    const messages = this.chatMessages.value ?? []
    this.chatMessages.value = [...messages.slice(count)]
  }

  clear() {
    this.chatMessages.value = []
  }

  setMessageFilter(filter: (message: PLVBaseIdEvent) => boolean) {
    this.messageFilter.value = filter
  }
}