import { lateInit } from '@polyvharmony/media-player-sdk';

@CustomDialog
export struct PLVSAConfirmDialog {
  controller?: CustomDialogController = lateInit()
  hasTitle: boolean = true
  title: string | Resource = $r('app.string.plvsa_confirm_dialog_title')
  hasContent: boolean = true
  content: string | Resource = $r('app.string.plvsa_confirm_dialog_content')
  hasConfirm: boolean = true
  confirmText: string | Resource = $r('app.string.plvsa_confirm_dialog_confirm')
  hasCancel: boolean = true
  cancelText: string | Resource = $r('app.string.plvsa_confirm_dialog_cancel')
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
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .fontSize(18)
          .textAlign(TextAlign.Center)
      }

      if (this.hasContent) {
        Text(this.content)
          .fontColor('#BFFFFFFF')
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
            .fontColor('#0382FF')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .borderColor('#0080FF')
            .borderWidth(1)
            .padding({
              top: 11,
              bottom: 11
            })
            .onClick(() => {
              this.onClickCancel(this.controller)
            })
        }
        if (this.hasCancel && this.hasConfirm) {
          Blank()
            .width(10)
        }
        if (this.hasConfirm) {
          Text(this.confirmText)
            .layoutWeight(1)
            .fontColor('#FFFFFF')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .linearGradient({
              angle: 90,
              colors: [
                ['#0080FF', 0],
                ['#3399FF', 0]
              ]
            })
            .padding({
              top: 11,
              bottom: 11
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
    .backgroundColor('#2C2C2C')
    .borderRadius(16)
    .padding({
      left: 24,
      right: 24,
      top: 20,
      bottom: 18
    })

  }
}