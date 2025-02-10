import { PLVLiveSceneSDK, PLVScheduledTask, PLVStreamerState, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver, seconds } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVSAStatusStreamDurationBar {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private durationText: string = "00:00:00"
  @State private isVisible: boolean = false
  private updateDurationTask: PLVScheduledTask | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.updateDurationTask = new PLVScheduledTask(
      () => {
        this.updateDuration()
      },
      0,
      seconds(1).toMillis()
    )
    this.updateDurationTask.start()
    this.sdk.streamerManager.streamerState.observe(streamerState => {
      this.isVisible = streamerState === PLVStreamerState.START
    }).pushTo(this.observers)
  }

  build() {
    Row() {
      Circle()
        .width(8)
        .height(8)
        .fill('#FF3B30')
      Text(this.durationText)
        .fontColor('#FFFFFF')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({
          left: 6
        })
    }
    .backgroundColor('#33000000')
    .borderRadius(18)
    .padding({
      left: 10,
      right: 10,
      top: 10,
      bottom: 10
    })
    .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  private updateDuration() {
    const startTimestamp = this.sdk.streamerManager.liveStartTimestamp.value
    const currentTimestamp = Date.now()
    if (startTimestamp === undefined || currentTimestamp < startTimestamp) {
      this.durationText = "00:00:00"
      return
    }
    this.durationText = PLVTimeUtils.generateTime(currentTimestamp - startTimestamp, true)
  }

  aboutToDisappear(): void {
    this.updateDurationTask?.cancel()
    this.updateDurationTask = undefined
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}