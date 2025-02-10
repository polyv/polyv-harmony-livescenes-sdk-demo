export type EventType = 'plvsa_chat_reply'

export class PLVSAEventHub {
  static on(event: EventType, callback: Function) {
    getContext().eventHub.on(event, callback)
  }

  static off(event: EventType, callback?: Function) {
    getContext().eventHub.off(event, callback)
  }

  static emit(event: EventType, ...args: Object[]) {
    getContext().eventHub.emit(event, ...args)
  }
}