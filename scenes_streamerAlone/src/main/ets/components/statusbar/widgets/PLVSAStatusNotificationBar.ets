import { PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { DerivedState, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';

@Component
export struct PLVSAStatusNotificationBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private isCameraEnable: boolean = false
  @State private isMicrophoneEnable: boolean = false
  @State private isVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const localVideoEnable = new DerivedState<boolean>(() => {
      return this.sdk.linkmicManager.localLinkMicViewer.value?.isVideoEnable?.value ?? false
    })
    const localAudioEnable = new DerivedState<boolean>(() => {
      return this.sdk.linkmicManager.localLinkMicViewer.value?.isAudioEnable?.value ?? false
    })
    const visible = new DerivedState(() => {
      return !(localVideoEnable.value ?? false) || !(localAudioEnable.value ?? false)
    })
    localVideoEnable.observe(it => this.isCameraEnable = it).pushTo(this.observers)
    localAudioEnable.observe(it => this.isMicrophoneEnable = it).pushTo(this.observers)
    visible.observe(it => this.isVisible = it).pushTo(this.observers)
  }

  build() {
    Row() {
      Text($r('app.string.plvsa_status_bar_notification'))
        .width(50)
        .height(24)
        .textAlign(TextAlign.Center)
        .fontColor('#FFFFFF')
        .fontSize(12)
        .linearGradient({
          angle: 90,
          colors: [
            ['#0080FF', 0],
            ['#3399FF', 1]
          ]
        })
        .borderRadius(16)

      Text(this.notificationContentText())
        .fontColor('#FFFFFF')
        .fontSize(14)
        .margin({
          left: 8
        })
    }
    .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
    .backgroundColor('#33000000')
    .borderRadius(18)
    .padding(8)
  }

  private notificationContentText(): string | Resource {
    if (!this.isCameraEnable && !this.isMicrophoneEnable) {
      return $r('app.string.plvsa_status_bar_notify_camera_microphone_disabled')
    } else if (!this.isCameraEnable) {
      return $r('app.string.plvsa_status_bar_notify_camera_disabled')
    } else if (!this.isMicrophoneEnable) {
      return $r('app.string.plvsa_status_bar_notify_microphone_disabled')
    } else {
      return ""
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}