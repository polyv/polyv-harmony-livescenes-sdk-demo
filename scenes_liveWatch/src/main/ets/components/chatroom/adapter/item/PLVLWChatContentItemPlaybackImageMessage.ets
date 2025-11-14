import { PLVChatPlaybackDataVO } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatItemActionCallback,
  chatItemImageDisplaySize,
  chatItemImageMaxSize,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemPlaybackImageMessage {
  message: PLVChatPlaybackDataVO = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private imageWidth: number = chatItemImageMaxSize
  @State private imageHeight: number = chatItemImageMaxSize

  aboutToAppear(): void {
    const imageSize = chatItemImageDisplaySize({
      width: this.message.chatImgContent?.size?.width ?? 1,
      height: this.message.chatImgContent?.size?.height ?? 1
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
      if (this.message.chatImgContent?.uploadImgUrl) {
        Image(this.message.chatImgContent?.uploadImgUrl)
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
  }
}