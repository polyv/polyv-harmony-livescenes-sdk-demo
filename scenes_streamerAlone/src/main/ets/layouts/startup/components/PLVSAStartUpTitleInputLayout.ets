import { PLVCommonConstants } from '@polyvharmony/live-scenes-sdk'

@Component
export struct PLVSAStartUpTitleInputLayout {
  @Link liveTitle: string
  @Link isVisible: boolean

  build() {
    if (this.isVisible) {
      RelativeContainer() {
        Column() {
          TextArea({
            placeholder: $r('app.string.plvsa_startup_title_placeholder'),
            text: $$this.liveTitle
          })
            .id('plvsa_startup_title_input_text_area')
            .width(PLVCommonConstants.FULL_PERCENT)
            .fontSize(20)
            .backgroundColor('transparent')
            .placeholderColor("#99FFFFFF")
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .onAppear(() => {
              focusControl.requestFocus('plvsa_startup_title_input_text_area')
            })

          Divider()
            .width(PLVCommonConstants.FULL_PERCENT)
            .height(2)
            .color('#99FFFFFF')
            .margin({
              top: 12
            })
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Center)
        .margin({
          top: 88
        })
        .padding({
          left: 48,
          right: 48
        })
      }
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .onClick(() => {
        this.isVisible = false
      })
    }
  }
}