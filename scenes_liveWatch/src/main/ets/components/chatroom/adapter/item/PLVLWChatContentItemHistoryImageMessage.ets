import { PLVHistoryChatImgEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  chatItemImageDisplaySize,
  chatItemImageMaxSize,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemHistoryImageMessage {
  message: PLVHistoryChatImgEvent = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private imageWidth: number = chatItemImageMaxSize
  @State private imageHeight: number = chatItemImageMaxSize
  @State private showLongPressPopup: boolean = false

  aboutToAppear(): void {
    const imageSize = chatItemImageDisplaySize({
      width: this.message.content?.size?.width ?? 1,
      height: this.message.content?.size?.height ?? 1
    })
    this.imageWidth = imageSize.width
    this.imageHeight = imageSize.height
  }

  build() {
    Column() {
      PLVLWChatContentItemSpeakContent({
        actor: this.message.user?.getActor(),
        actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
        actorColorBackground: actorBackgroundColor(this.message.user?.userType),
        nick: this.message.user?.nick,
        nickColor: nickForegroundColor(this.message.user?.userType)
      })
      if (this.message.content?.uploadImgUrl) {
        Image(this.message.content?.uploadImgUrl)
          .width(this.imageWidth)
          .height(this.imageHeight)
          .margin({
            top: 6
          })
          .onClick(() => {
            this.chatItemActionCallback.onClickImage?.(this.message)
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