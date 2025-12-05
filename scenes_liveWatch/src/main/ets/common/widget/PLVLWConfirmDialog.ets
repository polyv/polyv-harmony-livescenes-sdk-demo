import { lateInit } from '@polyvharmony/media-player-sdk';

@CustomDialog
export struct PLVLWConfirmDialog {
  controller?: CustomDialogController = lateInit()
  hasTitle: boolean = true
  title: string | Resource = $r('app.string.plvlw_confirm_dialog_title')
  hasContent: boolean = true
  content: string | Resource = $r('app.string.plvlw_confirm_dialog_content')
  hasConfirm: boolean = true
  confirmText: string | Resource = $r('app.string.plvlw_confirm_dialog_confirm')
  hasCancel: boolean = true
  cancelText: string | Resource = $r('app.string.plvlw_confirm_dialog_cancel')
  onClickConfirm: (controller: CustomDialogController | undefined) => void = (controller) => {
    controller?.close()
  }
  onClickCancel: (controller: CustomDialogController | undefined) => void = (controller) => {
    controller?.close()
  }

  build() {
    Column() {
      if (this.hasTitle) {
        Text(this.title)
          .fontColor('#000000')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .textAlign(TextAlign.Center)
      }

      if (this.hasContent) {
        Text(this.content)
          .fontColor('#CC000000')
          .fontSize(14)
          .textAlign(TextAlign.Center)
          .margin({
            top: 12
          })
      }

      Row() {
        if (this.hasCancel) {
          Text(this.cancelText)
            .layoutWeight(1)
            .fontColor('#3F76FC')
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .borderRadius(22)
            .borderColor('#3F76FC')
            .borderWidth(1)
            .padding({
              top: 7,
              bottom: 7
            })
            .onClick(() => {
              this.onClickCancel(this.controller)
            })
        }
        if (this.hasCancel && this.hasConfirm) {
          Blank()
            .width(12)
        }
        if (this.hasConfirm) {
          Text(this.confirmText)
            .layoutWeight(1)
            .fontColor('#FFFFFF')
            .fontSize(16)
            .textAlign(TextAlign.Center)
            .borderRadius(22)
            .backgroundColor('#3F76FC')
            .padding({
              top: 7,
              bottom: 7
            })
            .onClick(() => {
              this.onClickConfirm(this.controller)
            })
        }
      }
      .width('100%')
      .margin({
        top: 25
      })
    }
    .width(260)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: '#33000000'
    })
    .padding({
      left: 24,
      right: 24,
      top: 15,
      bottom: 24
    })

  }
}