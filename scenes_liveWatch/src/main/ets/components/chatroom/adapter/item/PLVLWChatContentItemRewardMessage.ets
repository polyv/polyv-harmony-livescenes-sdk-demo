import { PLVRewardEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVLWChatContentItemRewardMessage {
  message: PLVRewardEvent = lateInit()
  @State private name: string = ''
  @State private giftName: string = ''
  @State private giftImage: string = ''

  aboutToAppear(): void {
    this.name = this.message.content?.unick ?? ''
    this.giftName = this.message.content?.rewardContent ?? ''
    this.giftImage = this.message.content?.getGimg() ?? ''
  }

  build() {
    Column() {
      Text() {
        Span(`${this.name} `)
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_name_foreground_viewer'))

        Span($r('app.string.plvlw_reward_give', this.giftName))
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_reward_message_give_text'))

        Span(' ')
          .fontSize(14)

        ImageSpan(this.giftImage)
          .width(20)
          .height(20)
          .verticalAlign(ImageSpanAlignment.CENTER)
      }
      .align(Alignment.Center)
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