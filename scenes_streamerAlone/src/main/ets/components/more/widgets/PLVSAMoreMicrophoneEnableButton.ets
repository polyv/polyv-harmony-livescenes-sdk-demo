import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVSAMoreMicrophoneEnableButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private enable: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const localAudioEnable = new DerivedState<boolean>(() => {
      return this.sdk.linkmicManager.localLinkMicViewer.value?.isAudioEnable?.value ?? false
    })
    localAudioEnable.observe((audioEnable) => this.enable = audioEnable).pushTo(this.observers)
  }

  build() {
    Column() {
      Image(this.enable ? $r('app.media.plvsa_more_microphone_enable') : $r('app.media.plvsa_more_microphone_disable'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_microphone'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.sdk.linkmicManager.enableMicrophone(!this.enable)
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}