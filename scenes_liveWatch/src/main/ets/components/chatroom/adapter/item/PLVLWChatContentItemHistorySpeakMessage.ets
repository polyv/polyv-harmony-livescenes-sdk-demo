import { PLVHistorySpeakEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent,
  PLVLWChatQuoteContentLayout,
  PLVLWChatSpeakOverLengthLayout
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemHistorySpeakMessage {
  message: PLVHistorySpeakEvent = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private showLongPressPopup: boolean = false

  build() {
    Column() {
      if (this.message.quote) {
        PLVLWChatQuoteContentLayout({
          quote: this.message.quote
        })
        Blank()
          .height(1)
          .backgroundColor($r('app.color.plvlw_chat_content_quote_message_divider_color'))
          .margin({
            top: 4,
            bottom: 4
          })
      }

      PLVLWChatContentItemSpeakContent({
        actor: this.message.user?.getActor(),
        actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
        actorColorBackground: actorBackgroundColor(this.message.user?.userType),
        nick: this.message.user?.nick,
        nickColor: nickForegroundColor(this.message.user?.userType),
        speakMessage: this.message.content,
        speakMessageColor: $r('app.color.plvlw_chat_content_speak_message_color'),
        maxLines: this.message.overLen ? 5 : Number.MAX_SAFE_INTEGER
      })

      if (this.message.overLen) {
        Blank()
          .height(1)
          .backgroundColor($r('app.color.plvlw_chat_content_quote_message_divider_color'))
          .margin({
            top: 4,
            bottom: 4
          })
        PLVLWChatSpeakOverLengthLayout({
          message: this.message
        })
      }
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
          show: !this.message.overLen,
          onClick: () => {
            this.chatItemActionCallback.onClickCopy?.(this.message)
            this.showLongPressPopup = false
          }
        },
        reply: {
          show: true,
          onClick: () => {
            this.chatItemActionCallback.onClickReply?.(this.message)
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