import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus';

@Component
export struct PLVSAMoreCameraEnableButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private enable: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const localVideoEnable = new DerivedState<boolean>(() => {
      return this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable?.value ?? false
    })
    localVideoEnable.observe((videoEnable) => this.enable = videoEnable).pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.enable ? $r('app.media.plvsa_more_camera_enable') : $r('app.media.plvsa_more_camera_disable'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_camera'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      const toEnable = !this.enable
      this.sdk.linkmicManager.enableCamera(toEnable)
      this.pageDataBus.recoverSetting.update({
        isEnableCamera: toEnable
      })
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}