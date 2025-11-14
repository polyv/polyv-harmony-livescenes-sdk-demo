import { PLVHistoryFileShareEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  chatMessageAvatar,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemHistoryFileShareMessage {
  message: PLVHistoryFileShareEvent = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private showLongPressPopup: boolean = false

  build() {
    Column() {
      PLVLWChatContentItemSpeakContent({
        avatar: chatMessageAvatar(this.message.user?.getPic(), this.message.user?.userType),
        actor: this.message.user?.getActor(),
        actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
        actorColorBackground: actorBackgroundColor(this.message.user?.userType),
        nick: this.message.user?.nick,
        nickColor: nickForegroundColor(this.message.user?.userType)
      })

      Stack() {
        Text() {
          ImageSpan($r('app.media.plvlw_chatroom_file_share_icon_ppt'))
            .width(20)
            .height(20)
            .verticalAlign(ImageSpanAlignment.CENTER)

          Span(`  ${this.message.fileData?.name}`)
            .fontSize(14)
            .fontColor($r('app.color.plvlw_chat_file_share_text'))
        }
        .wordBreak(WordBreak.BREAK_ALL)
      }
      .backgroundColor($r('app.color.plvlw_chat_content_item_background'))
      .borderRadius(8)
      .padding({
        left: 8,
        right: 8,
        top: 7,
        bottom: 7
      })
      .margin({
        top: 6
      })
      .onClick(() => {
        this.chatItemActionCallback.onClickFileShare?.(this.message)
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