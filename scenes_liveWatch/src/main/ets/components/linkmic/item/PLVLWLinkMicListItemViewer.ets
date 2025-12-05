import {
  PLVCommonConstants,
  PLVLinkMicVideoRenderParam,
  PLVLinkMicViewer,
  PLVLiveSceneSDK
} from '@polyvharmony/live-scenes-sdk'
import { extendNumber, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWLinkmicItem } from './PLVLWLinkMicItemAdapter'

@Component
export struct PLVLWLinkMicListItemViewer {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  linkmicItem: PLVLWLinkmicItem = lateInit()
  viewer: PLVLinkMicViewer = lateInit()
  @State isVideoEnable: boolean = false
  @State isAudioEnable: boolean = false
  @State audioVolume: number = 0
  @State viewerName: string | Resource = ""
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.viewer.isVideoEnable.observe((videoEnable) => this.isVideoEnable = videoEnable).pushTo(this.observers)
    this.viewer.isAudioEnable.observe((audioEnable) => this.isAudioEnable = audioEnable).pushTo(this.observers)
    this.viewer.audioVolume.observe((audioVolume) => this.audioVolume = audioVolume).pushTo(this.observers)
    this.viewer.viewerName.observe((viewerName) => {
      this.viewerName = this.viewer.isMyself ? $r('app.string.plvlw_chat_me', viewerName ?? "", "") : (viewerName ?? "")
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      if (this.isVideoEnable) {
        // 摄像头画面
        XComponent({
          id: `${this.viewer.xcomponentId}-list`,
          type: "surface",
          libraryname: this.viewer.xcomponentLibraryName
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              `${this.viewer.xcomponentId}-list`
            )
            this.sdk.linkmicManager.setupVideoRender(renderParam)
          })
          .onDestroy(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              `${this.viewer.xcomponentId}-list`
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

      RelativeContainer() {
        // 音量提示图标
        Image(this.audioVolumeIcon())
          .id('linkmic_item_audio_volume_indicator')
          .width(16)
          .height(16)
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })
          .margin({
            left: 4,
            bottom: 4
          })

        // 连麦成员名称
        Text(this.viewerName)
          .id('linkmic_item_viewer_name')
          .fontColor('#FFFFFF')
          .fontSize(12)
          .alignRules({
            left: { anchor: 'linkmic_item_audio_volume_indicator', align: HorizontalAlign.End },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
            center: { anchor: 'linkmic_item_audio_volume_indicator', align: VerticalAlign.Center }
          })
          .margin({
            right: 8
          })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)
      }
    }
    .width(90)
    .height(90)
    .borderRadius(8)
    .clip(true)
  }

  private audioVolumeIcon(): Resource {
    if (!this.isAudioEnable) {
      return $r('app.media.plvlw_linkmic_audio_volume_closed')
    } else {
      const clampValue = extendNumber(this.audioVolume).coerceIn_ext(0, 100)
      const normalizeVolume = Math.round(clampValue / 10) * 10
      return $r(`app.media.plvlw_linkmic_audio_volume_value_${normalizeVolume}`)
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}