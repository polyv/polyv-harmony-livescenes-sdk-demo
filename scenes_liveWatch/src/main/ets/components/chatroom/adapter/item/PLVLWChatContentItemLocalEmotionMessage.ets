import { PLVEmotionEvent, PLVImageBean, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import {
  actorBackgroundColor,
  ChatContentItemLongPressPopup,
  ChatItemActionCallback,
  chatItemImageDisplaySize,
  chatItemImageMaxSize,
  chatMessageAvatar,
  nickForegroundColor,
  PLVLWChatContentItemSpeakContent
} from './chat-content-item-common'

@Component
export struct PLVLWChatContentItemLocalEmotionMessage {
  message: PLVEmotionEvent = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('chatItemActionCallback') chatItemActionCallback: ChatItemActionCallback
  @State private imageUrl: string | Resource | undefined = undefined
  @State private imageWidth: number = chatItemImageMaxSize
  @State private imageHeight: number = chatItemImageMaxSize
  @State private showLongPressPopup: boolean = false

  aboutToAppear(): void {
    const image = PLVImageBean.toImageBeanForEmotion(this.message, this.sdk.chatroomManager.emotions)
    this.imageUrl = image.url
    const imageSize = chatItemImageDisplaySize({
      width: image.width,
      height: image.height
    })
    this.imageWidth = imageSize.width
    this.imageHeight = imageSize.height
  }

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