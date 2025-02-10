import { PLVSAMoreMixLayoutSelectLayout } from './PLVSAMoreMixLayoutSelectLayout';

@Component
export struct PLVSAMoreMixLayoutButton {
  iconPadding: number = 8
  onClicked: (origin: () => void) => void = (origin) => {
    origin()
  }
  private readonly mixLayoutSelectController: CustomDialogController = new CustomDialogController({
    builder: PLVSAMoreMixLayoutSelectLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Column() {
      Image($r('app.media.plvsa_more_mix_layout_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_mix_layout'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onClicked(() => {
        this.mixLayoutSelectController.open()
      })
    })
  }
}