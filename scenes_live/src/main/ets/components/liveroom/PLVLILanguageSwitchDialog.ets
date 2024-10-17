import { PLVCommonConstants, PLVDeviceUtils, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk'

@Preview
@CustomDialog
export struct PLVLILanguageSwitchDialog {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  controller?: CustomDialogController

  build() {
    Stack() {
      Column() {
        Button($r('app.string.plvli_live_language_switch_zh'), { type: ButtonType.Normal })
          .padding({ top: 16, bottom: 16 })
          .backgroundColor(Color.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .fontSize(16)
          .fontColor('#000000')
          .onClick(() => {
            if (!this.sdk?.languageManager.isZH()) {
              this.confirmSwitchLanguage(true)
              return
            }
            this.controller?.close()
          })
        Divider()
          .strokeWidth(1)
          .color('#f2f2f2')
        Button($r('app.string.plvli_live_language_switch_en'), { type: ButtonType.Normal })
          .padding({ top: 16, bottom: 16 })
          .backgroundColor(Color.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .fontSize(16)
          .fontColor('#000000')
          .onClick(() => {
            if (!this.sdk?.languageManager.isEN()) {
              this.confirmSwitchLanguage(false)
              return
            }
            this.controller?.close()
          })
        Divider()
          .strokeWidth(8)
          .color('#f2f2f2')
        Button($r('app.string.plvli_common_dialog_cancel'), { type: ButtonType.Normal })
          .padding({ top: 16, bottom: 16 })
          .backgroundColor(Color.Transparent)
          .width(PLVCommonConstants.FULL_PERCENT)
          .fontSize(16)
          .fontColor('#000000')
          .onClick(() => {
            this.controller?.close()
          })
      }
      .padding({ bottom: PLVDeviceUtils.getNavigationIndicatorHeight() - 6 })
      .width(PLVCommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.End)
    }
    .borderRadius({
      topLeft: 12,
      topRight: 12,
      bottomLeft: 0,
      bottomRight: 0
    })
    .width(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#ffffff')
  }

  confirmSwitchLanguage(changToZH: boolean) {
    changToZH ? this.sdk?.languageManager.changeToZH() : this.sdk?.languageManager.changeToEN()
    this.controller?.close()
    // reserve temporarily
    // AlertDialog.show({
    //   message: $r('app.string.plvli_live_language_switch_hint'),
    //   autoCancel: true,
    //   alignment: DialogAlignment.Center,
    //   primaryButton: {
    //     value: $r('app.string.plvli_common_dialog_cancel'),
    //     action: () => {
    //     }
    //   },
    //   secondaryButton: {
    //     value: $r('app.string.plvli_common_dialog_confirm'),
    //     action: () => {
    //       changToZH ? this.sdk?.languageManager.changeToZH() : this.sdk?.languageManager.changeToEN()
    //       this.controller?.close()
    //     }
    //   }
    // })
  }
}