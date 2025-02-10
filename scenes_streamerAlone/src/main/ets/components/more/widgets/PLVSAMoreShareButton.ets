import { PLVSAMoreShareLayout } from './PLVSAMoreShareLayout'

@Component
export struct PLVSAMoreShareButton {
  iconPadding: number = 8
  onClicked: (origin: () => void) => void = (origin) => {
    origin()
  }
  private readonly controller = new CustomDialogController({
    builder: PLVSAMoreShareLayout(),
    customStyle: true
  })

  build() {
    Column() {
      Image($r('app.media.plvsa_more_share_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_share_title'))
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