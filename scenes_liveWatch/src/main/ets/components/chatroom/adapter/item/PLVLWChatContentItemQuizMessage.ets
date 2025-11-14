import { PLVTAnswerEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  chatItemImageDisplaySize,
  chatMessageAvatar,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemQuizMessage {
  message: PLVTAnswerEvent = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private isImageEvent: boolean = false
  @State private imageUrl: string | Resource | undefined = undefined
  @State private imageWidth: number = 0
  @State private imageHeight: number = 0
  @State private showLongPressPopup: boolean = false

  aboutToAppear(): void {
    if (this.message.isImgType()) {
      this.isImageEvent = true
      this.imageUrl = this.message.image?.url
      const imageSize = chatItemImageDisplaySize({
        width: this.message.image?.width ?? 1,
        height: this.message.image?.height ?? 1
      })
      this.imageWidth = imageSize.width
      this.imageHeight = imageSize.height
    } else {
      this.isImageEvent = false
    }
  }

  build() {
    Column() {
      if (!this.isImageEvent) {
        PLVLWChatContentItemSpeakContent({
          avatar: chatMessageAvatar(this.message.user?.getPic(), this.message.user?.userType),
          actor: this.message.user?.getActor(),
          actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
          actorColorBackground: actorBackgroundColor(this.message.user?.userType),
          nick: this.message.user?.nick,
          nickColor: nickForegroundColor(this.message.user?.userType),
          speakMessage: this.message.content,
          speakMessageColor: $r('app.color.plvlw_chat_content_speak_message_color')
        })
      } else {
        PLVLWChatContentItemSpeakContent({
          avatar: chatMessageAvatar(this.message.user?.getPic(), this.message.user?.userType),
          actor: this.message.user?.getActor(),
          actorColorForeground: $r('app.color.plvlw_chat_actor_foreground_color'),
          actorColorBackground: actorBackgroundColor(this.message.user?.userType),
          nick: this.message.user?.nick,
          nickColor: nickForegroundColor(this.message.user?.userType)
        })
        if (this.imageUrl) {
          Image(this.imageUrl)
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
          show: !this.isImageEvent,
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
          this.showLongPressPopup = !this.isImageEvent
        })
    )
  }
}