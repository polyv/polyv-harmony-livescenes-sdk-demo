import { PLVLinkMicCameraFacing, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVSAMoreCameraMirrorButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private enable: boolean = true
  @State private isMirror: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const mirrorEnable = new DerivedState<boolean>(() => {
      const videoEnable = this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable?.value ?? false
      const cameraFacingFront = this.sdk.linkmicManager.cameraFacing.value === PLVLinkMicCameraFacing.FRONT
      return videoEnable && cameraFacingFront
    })
    mirrorEnable.observe((mirrorEnable) => this.enable = mirrorEnable).pushTo(this.observers)
    this.sdk.linkmicManager.renderMirror.observe((isMirror) => this.isMirror = isMirror)
      .pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.mirrorIcon())
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_camera_mirror'))
        .fontColor(this.enable ? "#FFFFFF" : "#99FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .enabled(this.enable)
    .onClick(() => {
      this.sdk.linkmicManager.setLocalMirror(!this.isMirror)
    })
  }

  private mirrorIcon(): Resource {
    if (!this.enable) {
      return $r('app.media.plvsa_more_camera_mirror_disable')
    } else {
      if (this.isMirror) {
        return $r('app.media.plvsa_more_camera_mirror_enable_on')
      } else {
        return $r('app.media.plvsa_more_camera_mirror_enable_off')
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}