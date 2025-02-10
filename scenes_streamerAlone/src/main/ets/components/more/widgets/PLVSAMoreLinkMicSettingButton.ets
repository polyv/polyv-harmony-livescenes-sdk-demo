import { PLVSAMoreLinkMicSettingLayout } from './PLVSAMoreLinkMicSettingLayout'

@Component
export struct PLVSAMoreLinkMicSettingButton {
  iconPadding: number = 8
  onClicked: (origin: () => void) => void = (origin) => {
    origin()
  }
  private readonly linkmicSettingDialog = new CustomDialogController({
    builder: PLVSAMoreLinkMicSettingLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Column() {
      Image($r('app.media.plvsa_more_linkmic_setting_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_linkmic_setting_text'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onClicked(() => {
        this.linkmicSettingDialog.open()
      })
    })
  }

}