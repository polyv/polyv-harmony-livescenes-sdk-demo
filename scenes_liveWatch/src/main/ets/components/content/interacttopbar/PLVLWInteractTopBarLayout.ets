import { PLVChannelData, PLVCommonConstants, PLVLiveScene, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { DescTabData } from '../tabcontent/tab/PLVLWDescTabLayout';
import { createDescDialog, showDescDialog } from './bar/PLVLWTopBarDescDialogLayout';

@Preview
@Component
export struct PLVLWInteractTopBarLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State isLayoutVisible: boolean = true
  private liveScene: PLVLiveScene | undefined = this.channelData?.liveScene
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onLayoutData()
    createDescDialog(this.sdk.uniqueId, new DescTabData(this.sdk, this.channelData, this.layoutDataBus))
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Row({ space: 8 }) {
      if (PLVLiveScene.PORTRAIT_TEMPLATE === this.liveScene) {
        Text() {
          ImageSpan($r('app.media.plvlw_interact_top_bar_intro_icon'))
            .width(12)
            .height(12)
            .verticalAlign(ImageSpanAlignment.CENTER)
            .margin({ right: 4 })
          Span($r('app.string.plvlw_live_intro_2'))
        }
        .textAlign(TextAlign.Center)
        .padding({
          left: 8,
          right: 8,
          top: 5,
          bottom: 5
        })
        .backgroundColor($r('app.color.plvlw_neutral_light_black_20'))
        .borderRadius(20)
        .fontSize(12)
        .fontColor($r('app.color.plvlw_neutral_dark_white'))
        .onClick(() => {
          showDescDialog(this.sdk.uniqueId)
        })
      }
    }
    .visibility(this.isLayoutVisible ? Visibility.Visible : Visibility.None)
    .padding({ left: 12, right: 12, bottom: 8 })
    .height(PLVCommonConstants.AUTO)
    .width(PLVCommonConstants.FULL_PERCENT)
  }

  onLayoutData() {
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value ?? true
      const isVisible = this.layoutDataBus.playerControllerStatus.value?.visible ?? false
      const isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
      this.isLayoutVisible = isPortrait || (isVisible && !isLocked)
    }).pushTo(this.observers)
  }
}