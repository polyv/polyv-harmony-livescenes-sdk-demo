import { PLVLiveSceneSDK, PLVLocalQuizEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemLocalQuizMessage {
  message: PLVLocalQuizEvent = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private showLongPressPopup: boolean = false

  build() {
    Column() {
      PLVLWChatContentItemSpeakContent({
        actor: this.sdk.channelData.viewerActor,
        actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
        actorColorBackground: actorBackgroundColor(this.sdk.channelData.viewerType),
        nick: this.sdk.channelData.viewerName,
        nickColor: nickForegroundColor(this.sdk.channelData.viewerType),
        speakMessage: this.message.quizMessage,
        speakMessageColor: $r('app.color.plvlw_chat_content_speak_message_color')
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 8,
      right: 8,
      top: 3,
      bottom: 3
    })
    .borderRadius(16)
    .backgroundColor($r('app.color.plvlw_chat_content_item_background'))
    .bindPopup(this.showLongPressPopup, {
      builder: ChatContentItemLongPressPopup({
        copy: {
          show: true,
          onClick: () => {
            this.chatItemActionCallback.onClickCopy?.(this.message)
            this.showLongPressPopup = false
          }
        }
      }),
      placement: Placement.Top,
      backgroundBlurStyle: BlurStyle.NONE,
      popupColor: '#BF1B202D',
      radius: 4,
      onStateChange: (event) => {
        this.showLongPressPopup = event.isVisible
      }
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          this.showLongPressPopup = true
        })
    )
  }
}