import { PLVLinkMicCameraFacing, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus';

@Component
export struct PLVSAMoreCameraFacingButton {
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
      Image(this.enable ? $r('app.media.plvsa_more_camera_facing_enable') : $r('app.media.plvsa_more_camera_facing_disable'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_camera_facing_switch'))
        .fontColor(this.enable ? "#FFFFFF" : "#99FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .enabled(this.enable)
    .onClick(() => {
      this.sdk.linkmicManager.switchCamera()
      const newFacingFront = this.sdk.linkmicManager.cameraFacing.value === PLVLinkMicCameraFacing.FRONT
      if (!newFacingFront) {
        this.sdk.linkmicManager.setLocalMirror(false)
      }
      this.pageDataBus.recoverSetting.update({
        isFrontCamera: newFacingFront
      })
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}