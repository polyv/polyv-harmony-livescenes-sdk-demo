import {
  PLVLinkMicVideoRenderParam, PLVLinkMicViewer, PLVLiveSceneSDK
} from '@polyvharmony/live-scenes-sdk'
import { lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLinkmicItem } from './PLVLWLinkMicItemAdapter'

@Component
export struct PLVLWLinkMicMainItemViewer {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  linkmicItem: PLVLWLinkmicItem = lateInit()
  viewer: PLVLinkMicViewer = lateInit()
  @State isVideoEnable: boolean = false
  @State isAudioEnable: boolean = false
  @State viewerName: string | Resource = ""
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.viewer.isVideoEnable.observe((videoEnable) => this.isVideoEnable = videoEnable).pushTo(this.observers)
    this.viewer.isAudioEnable.observe((audioEnable) => this.isAudioEnable = audioEnable).pushTo(this.observers)
    this.viewer.viewerName.observe((viewerName) => {
      this.viewerName = this.viewer.isMyself ? $r('app.string.plvlw_chat_me', viewerName ?? "", "") : (viewerName ?? "")
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      if (this.isVideoEnable) {
        // 摄像头画面
        XComponent({
          id: `${this.viewer.xcomponentId}-main`,
          type: "surface",
          libraryname: this.viewer.xcomponentLibraryName
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              `${this.viewer.xcomponentId}-main`
            )
            this.sdk.linkmicManager.setupVideoRender(renderParam)
          })
          .onDestroy(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              `${this.viewer.xcomponentId}-main`
            )
            this.sdk.linkmicManager.removeVideoRender(renderParam)
          })
      } else {
        // 未开启摄像头占位图
        Stack() {
          Image($r('app.media.plvlw_linkmic_video_disabled_placeholder'))
            .width(48)
            .height(48)
        }
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 45,
          colors: [
            ['#383F64', 0],
            ['#2D324C', 1]
          ]
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}