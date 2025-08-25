@Component
export struct MoreSettingActionView {
  @Prop icon: ResourceStr
  @Prop iconColor: ResourceColor | undefined = undefined
  @Prop title: ResourceStr
  @Prop titleColor: ResourceColor = $r('app.color.plvlw_more_setting_action_title')

  build() {
    Column() {
      Image(this.icon)
        .width(30)
        .height(30)
        .objectFit(ImageFit.Contain)
        .fillColor(this.iconColor)

      Text(this.title)
        .fontSize(12)
        .fontColor(this.titleColor)
        .textAlign(TextAlign.Center)
        .margin({
          top: 5
        })
    }
    .width('25%')
    .padding({
      top: 12,
      bottom: 12
    })
  }
}

export class MoreSettingActionCallback {
  hideMoreSettingDialog?: () => void
}