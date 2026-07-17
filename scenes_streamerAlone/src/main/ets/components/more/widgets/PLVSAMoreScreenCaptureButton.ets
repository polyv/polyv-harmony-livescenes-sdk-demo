import { PLVLiveSceneSDK, PLVStreamerState, PLVToastUtils } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVSAMoreScreenCaptureButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isStartScreenCapture: boolean = false
  @State private isStreamerStarted: boolean = false
  @State private isSupportScreenCapture: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.isStartScreenCapture = this.sdk.streamerManager.isStartScreenCapture.value ?? false
    this.isSupportScreenCapture = this.sdk.streamerManager.sdkSupportScreenCapture.value ?? false
    this.isStreamerStarted = this.sdk.streamerManager.streamerState.value === PLVStreamerState.START

    this.sdk.streamerManager.isStartScreenCapture
      .observe(isStart => this.isStartScreenCapture = isStart)
      .pushTo(this.observers)
    this.sdk.streamerManager.sdkSupportScreenCapture
      .observe(isSupport => this.isSupportScreenCapture = isSupport)
      .pushTo(this.observers)
    this.sdk.streamerManager.streamerState
      .observe(state => this.isStreamerStarted = state === PLVStreamerState.START)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.isStartScreenCapture
        ? $r('app.media.plvsa_streamer_share_screen_selected')
        : $r('app.media.plvsa_streamer_share_screen_normal'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text(this.isStartScreenCapture
        ? $r('app.string.plvsa_more_screen_capture_stop')
        : $r('app.string.plvsa_more_screen_capture_start'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      if (this.isStartScreenCapture) {
        const ret = this.sdk.streamerManager.stopScreenCapture()
        if (ret !== 0) {
          PLVToastUtils.shortShow($r('app.string.plvsa_more_screen_capture_stop_fail', `${ret}`))
        }
        return
      }
      if (!this.isSupportScreenCapture) {
        PLVToastUtils.shortShow($r('app.string.plvsa_more_screen_capture_not_support'))
        return
      }
      if (!this.isStreamerStarted) {
        PLVToastUtils.shortShow($r('app.string.plvsa_more_screen_capture_need_streamer_start'))
        return
      }
      const ret = this.sdk.streamerManager.startScreenCapture()
      if (ret !== 0) {
        PLVToastUtils.shortShow($r('app.string.plvsa_more_screen_capture_start_fail', `${ret}`))
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}
