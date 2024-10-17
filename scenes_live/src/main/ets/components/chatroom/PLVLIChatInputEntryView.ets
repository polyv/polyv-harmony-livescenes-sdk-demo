import { ChannelMenusBean, PLVCommonConstants } from '@polyvharmony/live-scenes-sdk'

@Preview
@Component
export struct PLVLIChatInputEntryView {
  @Link isQuizSelected: boolean
  @Link isShowChatInputLayout: boolean
  @Link quizMenu: ChannelMenusBean | undefined
  @Link isCloseRoom: boolean
  @Link isFocusModeOpen: boolean

  build() {
    Row() {
      Text() {
        ImageSpan($r('app.media.plvli_chat_msg'))
          .width(14)
          .height(14)
          .margin({ right: 6, left: 8 })
          .verticalAlign(ImageSpanAlignment.CENTER)
        Span(this.inputEntryText())
          .fontSize(14)
          .fontColor('#99ffffff')
          .width(PLVCommonConstants.FULL_PERCENT)
      }
      .layoutWeight(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(1)

      if (this.quizMenu) {
        Image(this.isQuizSelected ? $r('app.media.plvli_chat_quiz_selected') : $r('app.media.plvli_chat_quiz_default'))
          .width(26)
          .height(26)
          .padding(4)
          .margin({ right: 4 })
          .draggable(false)
          .onClick(() => {
            this.isQuizSelected = !this.isQuizSelected
          })
      }
    }
    .onClick(() => {
      if ((!this.isCloseRoom && !this.isFocusModeOpen) || this.isQuizSelected) {
        this.isShowChatInputLayout = true
      }
    })
    .backgroundColor('#73000000')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.End)
    .borderRadius(100)
    .height(32)
    .constraintSize({ minWidth: 150, maxWidth: 180 })
  }

  inputEntryText() {
    return this.isQuizSelected ? $r('app.string.plvli_chat_input_tips_quiz') :
      this.isCloseRoom ? $r('app.string.plvli_chat_input_tips_chatroom_close') :
        this.isFocusModeOpen ? $r('app.string.plvli_chat_input_tips_focus') :
        $r('app.string.plvli_chat_input_tips_chat')
  }
}