import { PLVCommonConstants, PLVDeviceUtils, PLVSocketUserBean, PLVTextUtils, PLVToastUtils, PLVUtils } from '@polyvharmony/live-scenes-sdk'
import PLVLIFaceManager from '../../common/PLVLIFaceManager'
import { getActorBgByUserType } from './PLVLIChatListItem'

@Preview
@CustomDialog
export struct PLVLIChatOverLengthMessageDialog {
  controller?: CustomDialogController
  scroller: Scroller = new Scroller()
  @Link nick: string | Resource | undefined
  @Link actor: string | undefined
  @Link userType: string | undefined
  @Link fullMessage: string

  build() {
    Stack() {
      Column() {
        Text($r('app.string.plvli_chat_full_text'))
          .width(PLVCommonConstants.FULL_PERCENT)
          .textAlign(TextAlign.Start)
          .fontSize(18)
          .fontColor('#F0F1F5')
        Scroll(this.scroller) {
          Text() {
            if (this.actor && PLVSocketUserBean.isSpecialType(this.userType)) {
              Span(` ${this.actor} `)
                .fontColor('#ffffff')
                .textBackgroundStyle({ color: getActorBgByUserType(this.userType), radius: 6 })
                .fontSize(12)
            }
            Span(this.nick)
              .fontColor('#FFD16B')
              .fontSize(14)
            ForEach(PLVTextUtils.parseString(this.fullMessage), (data: string) => {
              if (typeof PLVLIFaceManager.getFace(data) === 'string') {
                Span(PLVLIFaceManager.getFace(data))
                  .fontColor('#ffffff')
                  .fontSize(14)
              } else {
                ImageSpan(PLVLIFaceManager.getFace(data))
                  .width(21)
                  .height(21)
                  .verticalAlign(ImageSpanAlignment.CENTER)
              }
            })
          }
        }
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .margin({ top: 24, bottom: 24 })
        .height(0)
        .layoutWeight(1)

        Button($r('app.string.plvli_chat_copy'))
          .width(88)
          .height(28)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            PLVUtils.copyText(this.fullMessage).then(() => {
              PLVToastUtils.shortShow($r('app.string.plvli_chat_copy_success'))
            })
          })
      }
      .padding({
        left: 24,
        right: 24,
        top: 24,
        bottom: PLVDeviceUtils.getNavigationIndicatorHeight() + 24
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: 12,
      bottomLeft: 0,
      bottomRight: 0
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .height('65%')
    .backgroundColor('#464646')
    .backdropBlur(8)
  }
}