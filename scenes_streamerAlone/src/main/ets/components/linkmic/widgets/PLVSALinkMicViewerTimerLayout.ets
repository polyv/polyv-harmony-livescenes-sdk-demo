import { PLVLinkMicViewer, PLVScheduledTask, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'
import { lateInit, seconds } from '@polyvharmony/media-player-sdk'

@Component
export struct PLVSALinkMicViewerTimerLayout {
  viewer: PLVLinkMicViewer = lateInit()
  @State private durationMs: number = 0
  private timerTask: PLVScheduledTask | null = null

  aboutToAppear(): void {
    this.timerTask = new PLVScheduledTask(
      () => {
        this.durationMs = Date.now() - this.viewer.linkmicStartTimestamp
      },
      0,
      seconds(1).toMillis()
    )
    this.timerTask.start()
  }

  build() {
    Row() {
      Image($r('app.media.plvsa_linkmic_viewer_timer_icon'))
        .width(10)
        .height(10)
      Text(PLVTimeUtils.generateTime(this.durationMs, true))
        .fontColor('#FFFFFF')
        .fontSize(12)
        .margin({
          left: 3
        })
    }
  }

  aboutToDisappear(): void {
    this.timerTask?.cancel()
  }
}