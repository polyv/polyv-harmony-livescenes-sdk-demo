import { PLVLiveSceneSDK, PLVToastUtils } from "@polyvharmony/live-scenes-sdk";
import { lateInit, MutableObserver } from "@polyvharmony/media-player-sdk";

@Component
export struct PLVSAMoreAllowLinkMicButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isOpenLinkMic: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelAllowRequestHandsUpLinkMic.observe(it => this.isOpenLinkMic = it).pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.isOpenLinkMic ? $r('app.media.plvsa_more_allow_viewer_linkmic_active') : $r('app.media.plvsa_more_allow_viewer_linkmic_inactive'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_linkmic_viewer_raise_hand_text'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(async () => {
      const toOpenLinkMic = !this.isOpenLinkMic
      let success: boolean = false
      if (toOpenLinkMic) {
        success = await this.sdk.linkmicManager.openLinkMic()
      } else {
        success = await this.sdk.linkmicManager.closeLinkMic()
      }
      if (success) {
        if (toOpenLinkMic) {
          PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_viewer_raise_hand_enable_toast'))
        } else {
          PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_viewer_raise_hand_disable_toast'))
        }
      } else {
        PLVToastUtils.shortShow($r('app.string.plvsa_linkmic_viewer_raise_hand_timeout_toast'))
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }

}