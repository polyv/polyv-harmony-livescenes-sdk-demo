import { PLVSAMorePushDowngradeLayout } from './PLVSAMorePushDowngradeLayout'

@Component
export struct PLVSAMorePushDowngradeButton {
  iconPadding: number = 8
  onClicked: (origin: () => void) => void = (origin) => {
    origin()
  }
  private readonly controller = new CustomDialogController({
    builder: PLVSAMorePushDowngradeLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Column() {
      Image($r('app.media.plvsa_more_push_downgrade_preference_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_push_downgrade_preference_title'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onClicked(() => {
        this.controller.open()
      })
    })
  }
}