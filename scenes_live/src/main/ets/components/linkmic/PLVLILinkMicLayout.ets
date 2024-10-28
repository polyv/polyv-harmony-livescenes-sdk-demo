import {
  PLVCommonConstants,
  PLVLinkMicVideoRenderParam,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVNetworkQuality
} from '@polyvharmony/live-scenes-sdk';
import { extendNumber, lateInit, MutableObserver } from '@polyvharmony/media-player-sdk';
import { display } from '@kit.ArkUI';
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

@Component
export struct PLVLILinkMicLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  private readonly screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
  private readonly screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
  @State linkmicViewers: PLVLinkMicViewer[] = []
  @State gridColumnsTemplate: string = '1fr 1fr'
  @State viewerItemWidth: number = this.screenWidth
  @State viewerItemHeight: number = this.screenHeight
  @State gridHeight: number | string = '100%'
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicViewers.observe((viewers) => {
      this.linkmicViewers = viewers
      if (viewers.length <= 1) {
        this.gridColumnsTemplate = '1fr'
        this.viewerItemWidth = this.screenWidth
        this.viewerItemHeight = this.screenHeight
        this.gridHeight = '100%'
      } else if (viewers.length <= 4) {
        this.gridColumnsTemplate = '1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 2)
        this.gridHeight = rows * this.viewerItemHeight
      } else {
        this.gridColumnsTemplate = '1fr 1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 3
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 3)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      }
    })
      .pushTo(this.observers)
  }

  build() {
    Stack() {
      LinkMicKeepBackgroundTask()
      Grid() {
        ForEach(
          this.linkmicViewers,
          (viewer: PLVLinkMicViewer) => {
            GridItem() {
              PLVLILinkMicViewerItemView({
                viewer: viewer
              })
            }
            .width(this.viewerItemWidth)
            .height(this.viewerItemHeight)
          },
          (viewer: PLVLinkMicViewer) => viewer.xcomponentId
        )
      }
      .width('100%')
      .height(this.gridHeight)
      .columnsTemplate(this.gridColumnsTemplate)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct PLVLILinkMicViewerItemView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  viewer: PLVLinkMicViewer = lateInit()
  @State isVideoEnable: boolean = false
  @State isAudioEnable: boolean = false
  @State audioVolume: number = 0
  @State viewerName: string | Resource = ""
  @State networkQualityIcon: Resource | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.viewer.isVideoEnable.observe((videoEnable) => this.isVideoEnable = videoEnable).pushTo(this.observers)
    this.viewer.isAudioEnable.observe((audioEnable) => this.isAudioEnable = audioEnable).pushTo(this.observers)
    this.viewer.audioVolume.observe((audioVolume) => this.audioVolume = audioVolume).pushTo(this.observers)
    this.viewerName = this.viewer.isMyself ? $r('app.string.plvli_chat_me', this.viewer.viewerName ?? "", "") : (this.viewer.viewerName ?? "")
    if (this.viewer.isMyself) {
      this.sdk.linkmicManager.linkmicNetworkQuality.observe((networkQuality) => {
        this.networkQualityIcon = this.getNetworkQualityIcon(networkQuality)
      })
        .pushTo(this.observers)
    }
  }

  build() {
    Stack() {
      if (this.isVideoEnable) {
        // 摄像头画面
        XComponent({
          id: this.viewer.xcomponentId,
          type: "surface",
          libraryname: this.viewer.xcomponentLibraryName
        })
          .width('100%')
          .height('100%')
          .onLoad(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              this.viewer.xcomponentId
            )
            this.sdk.linkmicManager.setVideoRender(renderParam)
          })
          .onDestroy(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              null
            )
            this.sdk.linkmicManager.setVideoRender(renderParam)
          })
      } else {
        // 未开启摄像头占位图
        Stack() {
          Image($r('app.media.plvli_linkmic_video_disabled_placeholder'))
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
            left: 6,
            bottom: 8
          })

        // 连麦成员名称
        Text(this.viewerName)
          .id('linkmic_item_viewer_name')
          .fontColor('#FFFFFF')
          .fontSize(14)
          .alignRules({
            left: { anchor: 'linkmic_item_audio_volume_indicator', align: HorizontalAlign.End },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
            center: { anchor: 'linkmic_item_audio_volume_indicator', align: VerticalAlign.Center }
          })
          .margin({
            left: 3,
            right: 10
          })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .ellipsisMode(EllipsisMode.END)

        if (this.networkQualityIcon !== undefined) {
          // 网络质量提示图标
          Image(this.networkQualityIcon)
            .width(12)
            .height(12)
            .alignRules({
              top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
              right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End },
            })
            .margin({
              right: 5,
              top: 3
            })
        }
      }
    }
    .width('100%')
    .height('100%')
  }

  private audioVolumeIcon(): Resource {
    if (!this.isAudioEnable) {
      return $r('app.media.plvli_linkmic_audio_volume_closed')
    } else {
      const clampValue = extendNumber(this.audioVolume).coerceIn_ext(0, 100)
      const normalizeVolume = Math.round(clampValue / 10) * 10
      return $r(`app.media.plvli_linkmic_audio_volume_value_${normalizeVolume}`)
    }
  }

  private getNetworkQualityIcon(quality: PLVNetworkQuality): Resource {
    switch (quality) {
      case PLVNetworkQuality.EXCELLENT:
      case PLVNetworkQuality.GOOD:
        return $r('app.media.plvli_network_quality_good_icon')
      case PLVNetworkQuality.POOR:
      case PLVNetworkQuality.BAD:
        return $r('app.media.plvli_network_quality_middle_icon')
      case PLVNetworkQuality.VERY_BAD:
      case PLVNetworkQuality.DISCONNECT:
      case PLVNetworkQuality.UNKNOWN:
      default:
        return $r('app.media.plvli_network_quality_poor_icon')
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicKeepBackgroundTask {
  private readonly context = getContext(this) as common.UIAbilityContext

  async aboutToAppear(): Promise<void> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    const wantAgentObject = await wantAgent.getWantAgent(wantAgentInfo)
    await backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.AUDIO_RECORDING, wantAgentObject)
  }

  build() {
  }

  async aboutToDisappear(): Promise<void> {
    await backgroundTaskManager.stopBackgroundRunning(this.context)
  }
}