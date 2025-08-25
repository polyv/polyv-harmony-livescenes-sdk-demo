import { PLVRedPaperResultEvent } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVLWChatContentItemRedPaperResultMessage {
  message: PLVRedPaperResultEvent = lateInit()

  build() {
    Column() {
      Text() {
        Span(`${this.message.nick}: `)
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_name_foreground_viewer'))
        Span($r('app.string.plvlw_chatroom_red_paper_result_receive'))
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_red_paper_result_receive_text'))
        Span(' ').fontSize(14)
        Span(this.message.getTypeName())
          .fontSize(14)
          .fontColor($r('app.color.plvlw_chat_red_paper_result_receive_type'))
        Span(' ').fontSize(14)
        ImageSpan($r('app.media.plvlw_chatroom_message_red_paper_icon'))
          .width(16)
          .height(16)
          .verticalAlign(ImageSpanAlignment.CENTER)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 8,
      right: 8,
      top: 3,
      bottom: 3
    })
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.plvlw_chat_content_item_background'))
  }
}