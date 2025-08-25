import {
  PLVBaseIdEvent,
  PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLoginEvent,
  PLVSocketOnEvent
} from '@polyvharmony/live-scenes-sdk'
import { delay, lateInit, PLVMediaPlayerAppContext, Promises } from '@polyvharmony/media-player-sdk'
import { display } from '@kit.ArkUI'

const MOVE_IN_DURATION = 500
const SHOW_DURATION = 3000
const HIDE_DURATION = 1000

/**
 * 聊天区顶部消息：观众进入直播间
 */
@Component
export struct PLVLWChatTopMessageBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private message: string = ' '
  @State private messageBackgroundColor: ResourceColor = $r('app.color.plvlw_chat_top_message_login_background')
  @State private messageTranslateX: number = -px2vp(display.getDefaultDisplaySync().width)
  @State private messageAlpha: number = 0
  private readonly messageCountMap = new Map<string, number>()
  private readonly messageQueue: MessageWrapper[] = []
  private messageShowing: boolean = false

  aboutToAppear(): void {
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
        case PLVLoginEvent.EVENT: {
          const loginEvent = PLVJSONUtils.toFillData(PLVLoginEvent, data)
          if (loginEvent) {
            this.onMessageEvent(event, loginEvent)
          }
          break;
        }
      }
    }, this)
  }

  build() {
    Row() {
      Text(this.message)
        .fontSize(12)
        .fontColor($r('app.color.plvlw_chat_top_message_text'))
        .backgroundColor(this.messageBackgroundColor)
        .padding({
          top: 1,
          bottom: 1,
          left: 8,
          right: 8
        })
        .borderRadius(12)
        .translate({
          x: this.messageTranslateX
        })
        .opacity(this.messageAlpha)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .padding({
      top: 4,
      bottom: 4
    })
  }

  private onMessageEvent(eventType: string, event: PLVBaseIdEvent) {
    switch (eventType) {
      case PLVLoginEvent.EVENT: {
        const loginEvent = event as PLVLoginEvent
        if (this.messageCountMap.has(eventType)) {
          const count = this.messageCountMap.get(eventType) ?? 0
          this.messageCountMap.set(eventType, count + 1)
        } else {
          const wrapper = new MessageWrapper()
          wrapper.eventType = eventType
          wrapper.buildMessage = (): string => {
            const count = this.messageCountMap.get(eventType) ?? 1
            const nick = loginEvent.user?.nick ?? ''
            const displayNick = nick.length > 5 ? `${nick.substring(0, 5)}...` : nick
            if (count <= 1) {
              return PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chatroom_login_message_single'), displayNick)
            } else {
              return PLVMediaPlayerAppContext.getString($r('app.string.plvlw_chatroom_login_message_multiple'), displayNick, count.toString())
            }
          }
          this.messageCountMap.set(eventType, 1)
          this.messageQueue.push(wrapper)
        }
        break;
      }
    }

    this.pickMessageToShow()
  }

  private async pickMessageToShow() {
    if (this.messageShowing) {
      return
    }
    const wrapper = this.messageQueue.shift()
    if (!wrapper) {
      return
    }

    this.message = wrapper.buildMessage?.() ?? ''
    this.messageCountMap.delete(wrapper.eventType ?? '')
    this.messageShowing = true
    this.messageTranslateX = -px2vp(display.getDefaultDisplaySync().width)
    this.messageAlpha = 1
    await this.animMoveIn()
    await delay(SHOW_DURATION)
    await this.animHide()
    this.messageShowing = false
    this.pickMessageToShow()
  }

  private animMoveIn() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: MOVE_IN_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.messageTranslateX = 0
    })
    return promise.promise
  }

  private animHide() {
    const promise = Promises.withResolvers<void>()
    this.getUIContext().animateTo({
      duration: HIDE_DURATION,
      onFinish: () => {
        promise.resolve()
      }
    }, () => {
      this.messageAlpha = 0
    })
    return promise.promise
  }

  aboutToDisappear(): void {

  }
}

class MessageWrapper {
  eventType?: string
  buildMessage?: () => string
}