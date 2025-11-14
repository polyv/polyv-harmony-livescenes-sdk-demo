import { PLVChatPlaybackDataVO } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatItemActionCallback,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent,
  PLVLWChatQuoteContentLayout
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemPlaybackSpeakMessage {
  message: PLVChatPlaybackDataVO = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback

  build() {
    Column() {
      if (this.message.quote) {
        PLVLWChatQuoteContentLayout({
          quote: this.message.chatQuote
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
        maxLines: Number.MAX_SAFE_INTEGER
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
  }
}