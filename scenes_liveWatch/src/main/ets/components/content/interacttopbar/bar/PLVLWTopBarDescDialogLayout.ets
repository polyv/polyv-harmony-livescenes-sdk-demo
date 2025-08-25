import { PLVCommonConstants, PLVDeviceUtils } from '@polyvharmony/live-scenes-sdk'
import { MutableObserver, watchStates } from '@polyvharmony/media-player-sdk'
import { createDialog, showDialog } from '../../../../common/PLVLWGlobalStateDialog'
import { DescTabData, PLVLWDescTabLayout } from '../../tabcontent/tab/PLVLWDescTabLayout'

export function createDescDialog(sdkId: number, data: DescTabData) {
  createDialog({
    uniqueId: sdkId,
    name: 'desc',
    wrapBuilder: wrapBuilder(descDialogLayout),
    params: data
  })
}

export function showDescDialog(sdkId: number, isShow: boolean = true) {
  showDialog({
    uniqueId: sdkId,
    name: 'desc',
    isShow: isShow
  })
}

@Builder
export function descDialogLayout(descTabData: DescTabData): void {
  PLVLWTopBarDescDialogLayout({ descTabData: descTabData })
}

@Preview
@Component
export struct PLVLWTopBarDescDialogLayout {
  @State descTabData?: DescTabData = undefined
  @State private isPortrait: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isPortrait = this.descTabData?.layoutDataBus?.isPortrait.value ?? true
    }).pushTo(this.observers)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Stack() {
      RelativeContainer() {
        Text($r('app.string.plvlw_live_intro'))
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .textAlign(TextAlign.Center)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.plvlw_neutral_light_black_80'))
          .id('titleText')

        PLVLWDescTabLayout({ isDialogStyle: true, descTabData: this.descTabData })
          .margin({ top: 15 })
          .alignRules({
            top: { anchor: 'titleText', align: VerticalAlign.Bottom },
          })
      }
      .padding({
        top: 16,
        bottom: PLVDeviceUtils.getNavigationIndicatorHeight() + 6
      })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
    }
    .borderRadius({
      topLeft: 12,
      topRight: this.isPortrait ? 12 : 0,
      bottomLeft: this.isPortrait ? 0 : 12,
      bottomRight: 0
    })
    .width(this.isPortrait ? PLVCommonConstants.FULL_PERCENT : PLVDeviceUtils.getMinDisplaySide())
    .height(this.isPortrait ? '60%' : PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_neutral_dark_white'))
  }
}