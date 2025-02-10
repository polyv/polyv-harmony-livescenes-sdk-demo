import { PLVSAStatusChannelInfoLayout } from './PLVSAStatusChannelInfoLayout'

@Component
export struct PLVSAStatusChannelInfoBar {
  private readonly channelInfoLayoutController = new CustomDialogController({
    builder: PLVSAStatusChannelInfoLayout(),
    alignment: DialogAlignment.BottomEnd,
    customStyle: true
  })

  build() {
    Row() {
      Image($r('app.media.plvsa_status_bar_channel_info_icon'))
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_status_bar_channel_info'))
        .fontColor('#FFFFFF')
        .fontSize(14)
        .margin({
          left: 4,
          right: 2
        })
      Image($r('app.media.plvsa_status_bar_channel_info_nav_icon'))
        .width(16)
        .height(16)
        .objectFit(ImageFit.Contain)
    }
    .backgroundColor('#33000000')
    .borderRadius(18)
    .padding({
      left: 10,
      right: 10,
      top: 8,
      bottom: 8
    })
    .onClick(() => {
      this.channelInfoLayoutController.open()
    })
  }
}