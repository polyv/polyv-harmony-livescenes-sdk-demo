import { PLVCommonConstants, PLVDeviceUtils, PLVSocketUserBean, PLVTextUtils, PLVToastUtils, PLVUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import { getActorBgByUserType } from './PLVSAChatListItem'
import PLVSAFaceManager from './PLVSAFaceManager'
import { display } from '@kit.ArkUI'

@Preview
@CustomDialog
export struct PLVSAChatOverLengthMessageDialog {
  controller?: CustomDialogController
  scroller: Scroller = new Scroller()
  @Link nick: string | Resource | undefined
  @Link actor: string | undefined
  @Link userType: string | undefined
  @Link fullMessage: string

  build() {
    if (this.isPortrait()) {
      PLVSAChatOverLengthMessageDialogPort({
        nick: this.nick,
        actor: this.actor,
        userType: this.userType,
        fullMessage: this.fullMessage
      })
    } else {
      PLVSAChatOverLengthMessageDialogLand({
        nick: this.nick,
        actor: this.actor,
        userType: this.userType,
        fullMessage: this.fullMessage
      })
    }
  }

  private isPortrait(): boolean {
    const orientation = display.getDefaultDisplaySync().orientation
    return orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
  }

}

@Component
struct PLVSAChatOverLengthMessageDialogPort {
  scroller: Scroller = new Scroller()
  nick: string | Resource | undefined
  actor: string | undefined
  userType: string | undefined
  fullMessage: string = lateInit()

  build() {
    Stack() {
      Column() {
        Text($r('app.string.plvsa_chat_full_text'))
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
              if (typeof PLVSAFaceManager.getFace(data) === 'string') {
                Span(PLVSAFaceManager.getFace(data))
                  .fontColor('#ffffff')
                  .fontSize(14)
              } else {
                ImageSpan(PLVSAFaceManager.getFace(data))
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

        Button($r('app.string.plvsa_chat_copy'))
          .width(88)
          .height(28)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            PLVUtils.copyText(this.fullMessage).then(() => {
              PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
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

@Component
struct PLVSAChatOverLengthMessageDialogLand {
  scroller: Scroller = new Scroller()
  nick: string | Resource | undefined
  actor: string | undefined
  userType: string | undefined
  fullMessage: string = lateInit()

  build() {
    Stack() {
      Column() {
        Text($r('app.string.plvsa_chat_full_text'))
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
              if (typeof PLVSAFaceManager.getFace(data) === 'string') {
                Span(PLVSAFaceManager.getFace(data))
                  .fontColor('#ffffff')
                  .fontSize(14)
              } else {
                ImageSpan(PLVSAFaceManager.getFace(data))
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

        Button($r('app.string.plvsa_chat_copy'))
          .width(88)
          .height(28)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            PLVUtils.copyText(this.fullMessage).then(() => {
              PLVToastUtils.shortShow($r('app.string.plvsa_chat_copy_success'))
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
      bottomLeft: 12
    })
    .width(330)
    .height(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#464646')
    .backdropBlur(8)
  }
}