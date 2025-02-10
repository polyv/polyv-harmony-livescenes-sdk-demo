import { PLVLinkMicPushResolutionRatio, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, toRaw } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVSAMoreResolutionRatioButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private ratio: PLVLinkMicPushResolutionRatio = PLVLinkMicPushResolutionRatio.RATIO_16_9
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.pushResolutionRatio.observe((ratio) => this.ratio = ratio)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.ratioIcon())
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_push_resolution_ratio'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.sdk.streamerManager.setPushResolutionRatio(this.nextResolutionRatio())
    })
  }

  private ratioIcon(): Resource {
    switch (toRaw(this.ratio)) {
      case PLVLinkMicPushResolutionRatio.RATIO_16_9:
      default:
        return $r('app.media.plvsa_more_push_resolution_ratio_16_9')
      case PLVLinkMicPushResolutionRatio.RATIO_4_3:
        return $r('app.media.plvsa_more_push_resolution_ratio_4_3')
    }
  }

  private nextResolutionRatio(): PLVLinkMicPushResolutionRatio {
    if (toRaw(this.ratio) === PLVLinkMicPushResolutionRatio.RATIO_16_9) {
      return PLVLinkMicPushResolutionRatio.RATIO_4_3
    } else {
      return PLVLinkMicPushResolutionRatio.RATIO_16_9
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}