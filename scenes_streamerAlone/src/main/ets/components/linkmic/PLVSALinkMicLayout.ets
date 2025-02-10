import {
  PLVCommonConstants,
  PLVLinkMicPushResolutionRatio,
  PLVLinkMicState,
  PLVLinkMicVideoRenderParam,
  PLVLinkMicViewer,
  PLVLiveSceneSDK,
  PLVStreamerState,
  PLVUserType
} from '@polyvharmony/live-scenes-sdk'
import {
  DerivedState,
  derivedStateOf,
  extendArray,
  extendNumber,
  isNullOrUndefined,
  lateInit,
  MutableObserver
} from '@polyvharmony/media-player-sdk'
import { PLVSAPageDataBus, PLVSAStreamerStage } from '../../common/PLVSAPageDataBus'
import { display } from '@kit.ArkUI'
import { common, wantAgent } from '@kit.AbilityKit'
import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import {
  PLVSALinkMicMemberControlActionSwitcher,
  PLVSALinkMicMemberControlDialog
} from './widgets/PLVSALinkMicMemberControlDialog'
import { PLVSALinkMicViewerTimerLayout } from './widgets/PLVSALinkMicViewerTimerLayout'

@Component
export struct PLVSALinkMicLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State streamerStage: PLVSAStreamerStage = PLVSAStreamerStage.STARTUP
  @State streamerState: PLVStreamerState = PLVStreamerState.NOT_START
  @State layoutType: PLVSALinkMicLayoutType = PLVSALinkMicLayoutType.TILE
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.initCameraMicrophone()
    this.sdk.streamerManager.streamerState.observe(it => this.streamerState = it)
      .pushTo(this.observers)
    this.pageDataBus.streamerStage.observe(it => this.streamerStage = it).pushTo(this.observers)
    this.pageDataBus.linkmicLayoutType.observe(it => this.layoutType = it).pushTo(this.observers)
  }

  private async initCameraMicrophone() {
    await this.sdk.linkmicManager.initPromise
    this.sdk.linkmicManager.enableCamera(true)
    this.sdk.linkmicManager.enableMicrophone(true)
  }

  build() {
    Stack() {
      if (this.streamerStage !== PLVSAStreamerStage.END) {
        LinkMicKeepBackgroundTask()
      }

      if (this.streamerStage === PLVSAStreamerStage.STARTUP) {
        LinkMicPreviewLayout()
      } else if (this.streamerStage === PLVSAStreamerStage.LIVE) {
        if (this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER) {
          LinkMicTeacherLayout()
        } else {
          LinkMicGuestLayout()
        }
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// <editor-fold defaultstate="collapsed" desc="开播前预览">

@Component
struct LinkMicPreviewLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State localLinkMicViewer: PLVLinkMicViewer | undefined = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.localLinkMicViewer.observe(it => this.localLinkMicViewer = it)
      .pushTo(this.observers)
  }

  build() {
    Stack() {
      if (this.localLinkMicViewer !== undefined) {
        PLVSALinkMicViewerItemView({
          viewer: this.localLinkMicViewer,
          viewerInfoOverlayVisible: false
        })
          .width('100%')
          .height('100%')
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="讲师">

@Component
struct LinkMicTeacherLayout {
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State layoutType: PLVSALinkMicLayoutType = PLVSALinkMicLayoutType.TILE
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.pageDataBus.linkmicLayoutType.observe(it => this.layoutType = it).pushTo(this.observers)
  }

  build() {
    if (this.layoutType === PLVSALinkMicLayoutType.TILE) {
      LinkMicTileLayout()
    } else if (this.layoutType === PLVSALinkMicLayoutType.SPEAKER) {
      LinkMicSpeakerLayout()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicTileLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
  private readonly screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
  @State linkmicViewers: PLVLinkMicViewer[] = []
  @State gridColumnsTemplate: string = '1fr 1fr'
  @State viewerItemWidth: number | string = this.screenWidth
  @State viewerItemHeight: number | string = this.screenHeight
  @State gridWidth: number | string = '100%'
  @State gridHeight: number | string = '100%'
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicViewers.observe((viewers) => {
      this.linkmicViewers = viewers
      this.layoutViewers()
    })
      .pushTo(this.observers)
  }

  build() {
    Stack() {
      Grid() {
        ForEach(
          this.linkmicViewers,
          (viewer: PLVLinkMicViewer) => {
            GridItem() {
              PLVSALinkMicViewerItemView({
                viewer: viewer
              })
            }
            .width(this.viewerItemWidth)
            .height(this.viewerItemHeight)
          },
          (viewer: PLVLinkMicViewer) => viewer.xcomponentId
        )
      }
      .width(this.gridWidth)
      .height(this.gridHeight)
      .columnsTemplate(this.gridColumnsTemplate)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  private layoutViewers() {
    const viewers = this.linkmicViewers
    const isPortrait = this.pageDataBus.isPortrait.value;
    if (viewers.length <= 1) {
      this.gridColumnsTemplate = '1fr'
      this.viewerItemWidth = '100%'
      this.viewerItemHeight = '100%'
      this.gridHeight = '100%'
    } else if (viewers.length <= 2) {
      this.gridColumnsTemplate = '1fr 1fr'
      if (isPortrait) {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        this.gridHeight = this.viewerItemHeight
      } else {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 3 * 2
        this.gridHeight = this.viewerItemHeight
      }
    } else if (viewers.length <= 4) {
      this.gridColumnsTemplate = '1fr 1fr'
      if (isPortrait) {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 2)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      } else {
        this.gridWidth = this.screenHeight * 1.5
        this.gridHeight = '100%'
        this.viewerItemWidth = '100%'
        this.viewerItemHeight = '50%'
      }
    } else {
      if (isPortrait) {
        this.gridColumnsTemplate = '1fr 1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 3
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 3)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      } else {
        this.gridColumnsTemplate = '1fr 1fr 1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 4
        this.viewerItemHeight = this.viewerItemWidth / 3 * 2
        const rows = Math.ceil(viewers.length / 4)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicSpeakerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
  private readonly screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
  @State isPortrait: boolean = true
  @State linkmicViewers: PLVLinkMicViewer[] = []
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.linkmicManager.channelLinkMicViewers.observe((viewers) => {
      this.linkmicViewers = viewers
    })
      .pushTo(this.observers)
    this.isPortrait = this.pageDataBus.isPortrait.value ?? true
  }

  build() {
    Stack() {
      if (this.linkmicViewers.length === 1) {
        PLVSALinkMicViewerItemView({
          viewer: this.linkmicViewers[0]
        })
          .width('100%')
          .height('100%')
      }

      if (this.linkmicViewers.length > 1) {
        RelativeContainer() {
          Stack() {
            PLVSALinkMicViewerItemView({
              viewer: this.linkmicViewers[0]
            })
          }
          .id('plvsa_linkmic_speaker_layout_main_container')
          .width(this.screenWidth / 3 * 2)
          .height('100%')

          Scroll() {
            Column() {
              ForEach(
                this.linkmicViewers.slice(1),
                (viewer: PLVLinkMicViewer) => {
                  GridItem() {
                    PLVSALinkMicViewerItemView({
                      viewer: viewer
                    })
                  }
                  .width('100%')
                  .aspectRatio(this.isPortrait ? 2 / 3 : 3 / 2)
                },
                (viewer: PLVLinkMicViewer) => viewer.xcomponentId
              )
            }
          }
          .id('plvsa_linkmic_speaker_layout_viewer_container')
          .height('100%')
          .scrollable(ScrollDirection.Vertical)
          .align(Alignment.TopStart)
          .alignRules({
            left: { anchor: "plvsa_linkmic_speaker_layout_main_container", align: HorizontalAlign.End },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
        }
        .width('100%')
        .height('100%')
        .padding({
          top: this.isPortrait ? 78 : 0
        })
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="嘉宾">

@Component
struct LinkMicGuestLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @State private streamState: PLVStreamerState = PLVStreamerState.NOT_START
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.sdk.streamerManager.streamerState.observe(it => this.streamState = it)
      .pushTo(this.observers)
  }

  build() {
    if (this.streamState === PLVStreamerState.START) {
      LinkMicGuestLiveTileLayout()
    } else {
      LinkMicGuestNoLiveLayout()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

@Component
struct LinkMicGuestNoLiveLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private localLinkMicViewer: PLVLinkMicViewer | undefined = undefined
  @State private isPortrait: boolean = true
  private observers: MutableObserver[] = []

  aboutToAppear() {
    this.sdk.linkmicManager.localLinkMicViewer.observe(it => this.localLinkMicViewer = it)
      .pushTo(this.observers)
    this.isPortrait = this.pageDataBus.isPortrait.value ?? true
  }

  build() {
    Stack() {
      Grid() {
        GridItem() {
          Column() {
            Image($r('app.media.plvsa_linkmic_no_stream_placeholder'))
              .width(92)
              .height(61)
              .objectFit(ImageFit.Contain)
            Text($r('app.string.plvsa_linkmic_no_stream_place_holder_text'))
              .fontSize(12)
              .fontColor('#E4E4E4')
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .linearGradient({
            angle: 45,
            colors: [
              ['#383F64', 0],
              ['#2D324C', 1]
            ]
          })
        }
        .aspectRatio(this.isPortrait ? 2 / 3 : 3 / 2)

        GridItem() {
          if (this.localLinkMicViewer) {
            PLVSALinkMicViewerItemView({
              viewer: this.localLinkMicViewer
            })
          }
        }
        .aspectRatio(this.isPortrait ? 2 / 3 : 3 / 2)
      }
      .width('100%')
      .height('100%')
      .columnsTemplate('1fr 1fr')
      .padding({
        top: this.isPortrait ? 78 : 0
      })
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
struct LinkMicGuestLiveTileLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private readonly screenWidth: number = px2vp(display.getDefaultDisplaySync().width)
  private readonly screenHeight: number = px2vp(display.getDefaultDisplaySync().height)
  @State linkmicViewers: PLVLinkMicViewer[] = []
  @State gridColumnsTemplate: string = '1fr 1fr'
  @State viewerItemWidth: number | string = this.screenWidth
  @State viewerItemHeight: number | string = this.screenHeight
  @State gridWidth: number | string = '100%'
  @State gridHeight: number | string = '100%'
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    const showChannelLinkMicViewersState = new DerivedState<PLVLinkMicViewer[]>(() => {
      const channelLinkMicViewers = this.sdk.linkmicManager.channelLinkMicViewers.value ?? []
      const localLinkMicViewer = this.sdk.linkmicManager.localLinkMicViewer.value
      const listContainMyself = channelLinkMicViewers?.find(it => it.linkmicId === localLinkMicViewer?.linkmicId) !== undefined
      if (listContainMyself) {
        return channelLinkMicViewers
      }
      return extendArray([...channelLinkMicViewers.slice(0, 1), localLinkMicViewer, ...channelLinkMicViewers.slice(1)])
        .filterNotNull_ext()
    })
    showChannelLinkMicViewersState.observe((viewers) => {
      this.linkmicViewers = viewers
      this.layoutViewers()
    })
      .pushTo(this.observers)
  }

  build() {
    Stack() {
      Grid() {
        ForEach(
          this.linkmicViewers,
          (viewer: PLVLinkMicViewer) => {
            GridItem() {
              PLVSALinkMicViewerItemView({
                viewer: viewer
              })
            }
            .width(this.viewerItemWidth)
            .height(this.viewerItemHeight)
          },
          (viewer: PLVLinkMicViewer) => viewer.xcomponentId
        )
      }
      .width(this.gridWidth)
      .height(this.gridHeight)
      .columnsTemplate(this.gridColumnsTemplate)
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }

  private layoutViewers() {
    const viewers = this.linkmicViewers
    const isPortrait = this.pageDataBus.isPortrait.value;
    if (viewers.length <= 1) {
      this.gridColumnsTemplate = '1fr'
      this.viewerItemWidth = '100%'
      this.viewerItemHeight = '100%'
      this.gridHeight = '100%'
    } else if (viewers.length <= 2) {
      this.gridColumnsTemplate = '1fr 1fr'
      if (isPortrait) {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        this.gridHeight = this.viewerItemHeight
      } else {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 3 * 2
        this.gridHeight = this.viewerItemHeight
      }
    } else if (viewers.length <= 4) {
      this.gridColumnsTemplate = '1fr 1fr'
      if (isPortrait) {
        this.viewerItemWidth = this.screenWidth / 2
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 2)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      } else {
        this.gridWidth = this.screenHeight * 1.5
        this.gridHeight = '100%'
        this.viewerItemWidth = '100%'
        this.viewerItemHeight = '50%'
      }
    } else {
      if (isPortrait) {
        this.gridColumnsTemplate = '1fr 1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 3
        this.viewerItemHeight = this.viewerItemWidth / 2 * 3
        const rows = Math.ceil(viewers.length / 3)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      } else {
        this.gridColumnsTemplate = '1fr 1fr 1fr 1fr'
        this.viewerItemWidth = this.screenWidth / 4
        this.viewerItemHeight = this.viewerItemWidth / 3 * 2
        const rows = Math.ceil(viewers.length / 4)
        this.gridHeight = rows * this.viewerItemHeight
        if (this.gridHeight > this.screenHeight) {
          this.gridHeight = '100%'
        }
      }
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="全屏显示">

@Component
export struct PLVSALinkMicFullScreenLayout {
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  @State private fullScreenViewer: PLVLinkMicViewer | null = null
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.pageDataBus.linkmicFullScreenViewer.observe(it => this.fullScreenViewer = it).pushTo(this.observers)
  }

  build() {
    if (this.fullScreenViewer !== null) {
      RelativeContainer() {
        Stack() {
          PLVSALinkMicViewerItemView({
            viewer: this.fullScreenViewer,
            customOnClickItemOnce: () => {
            },
            customOnClickItemTwice: () => {
              this.pageDataBus.linkmicFullScreenViewer.setValue(null)
            }
          })
        }
        .id('plvsa_linkmic_fullscreen_item_container')
        .width('100%')
        .height('100%')

        Image($r('app.media.plvsa_linkmic_fullscreen_exit_icon'))
          .id('plvsa_linkmic_fullscreen_exit_icon')
          .width(32)
          .height(32)
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .margin({
            top: 20,
            right: 12
          })
          .onClick(() => {
            this.pageDataBus.linkmicFullScreenViewer.setValue(null)
          })
      }
      .width('100%')
      .height('100%')
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="单个连麦视图item">

@Component
struct PLVSALinkMicViewerItemView {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  viewer: PLVLinkMicViewer = lateInit()
  viewerInfoOverlayVisible: boolean = true
  customOnClickItemOnce: () => void = () => {
    this.onClickItemViewOnce()
  }
  customOnClickItemTwice: () => void = () => {
    this.onClickItemViewTwice()
  }
  @State isVideoEnable: boolean = false
  @State isAudioEnable: boolean = false
  @State audioVolume: number = 0
  @State viewerName: string | Resource = ""
  @State guestLinkmicStateJoined: boolean = true
  @State speakerIconVisible: boolean = false
  @State isShowInFullScreen: boolean = false
  @State videoRatio: number | null = null
  private videoXComponentId: string = ""
  private memberControlDialogSwitcher: PLVSALinkMicMemberControlActionSwitcher | undefined = undefined
  private linkmicMemberControlDialogController: CustomDialogController | undefined = undefined
  private tapCountTimeout: number | undefined = undefined
  private tapCount = 0
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.memberControlDialogSwitcher = new PLVSALinkMicMemberControlActionSwitcher(this.sdk, this.viewer)
    this.viewer.isVideoEnable.observe((videoEnable) => this.isVideoEnable = videoEnable).pushTo(this.observers)
    this.viewer.isAudioEnable.observe((audioEnable) => this.isAudioEnable = audioEnable).pushTo(this.observers)
    this.viewer.audioVolume.observe((audioVolume) => this.audioVolume = audioVolume).pushTo(this.observers)
    this.viewer.viewerName.observe((viewerName) => {
      this.viewerName = this.viewer.isMyself ? $r('app.string.plvsa_chat_me', viewerName ?? "", "") : (viewerName ?? "")
    }).pushTo(this.observers)
    if (this.viewer.isMyself && this.sdk.channelData.viewerType !== PLVUserType.USERTYPE_TEACHER) {
      this.sdk.linkmicManager.linkmicState.observe((linkmicState) => {
        if (linkmicState === PLVLinkMicState.Joined) {
          this.guestLinkmicStateJoined = true
        } else {
          this.guestLinkmicStateJoined = false
        }
      })
        .pushTo(this.observers)
    }
    this.sdk.linkmicManager.channelMainViewLinkMicId.observe(mainViewLinkMicId => {
      const isSpeaker = !isNullOrUndefined(this.viewer.linkmicId) && this.viewer.linkmicId === mainViewLinkMicId
      this.speakerIconVisible = this.viewer.viewerType !== PLVUserType.USERTYPE_TEACHER && isSpeaker
    })
      .pushTo(this.observers)
    this.pageDataBus.linkmicFullScreenViewer.observe(fullScreenViewer => {
      this.isShowInFullScreen = this.viewer === fullScreenViewer
    }).pushTo(this.observers)
    const videoRatioState = derivedStateOf<number | null>(() => {
      const isLandscape = this.pageDataBus.isPortrait.value === false
      const ratio = this.sdk.streamerManager.pushResolutionRatio.value ?? PLVLinkMicPushResolutionRatio.RATIO_16_9
      const linkmicOnlyTeacher = (this.sdk.linkmicManager.channelLinkMicViewers.value ?? []).length <= 1
      if (isLandscape && this.viewer.isMyself && linkmicOnlyTeacher && ratio !== PLVLinkMicPushResolutionRatio.RATIO_16_9) {
        return ratio.ratio
      } else {
        return null
      }
    })
    videoRatioState.observe(it => this.videoRatio = it).pushTo(this.observers)
    this.videoXComponentId = `${this.viewer.xcomponentId}-${Date.now()}`
  }

  build() {
    Stack() {
      if (this.isVideoEnable && !this.isShowInFullScreen) {
        // 摄像头画面
        XComponent({
          id: this.videoXComponentId,
          type: "surface",
          libraryname: this.viewer.xcomponentLibraryName
        })
          .width(this.videoRatio === null ? '100%' : null)
          .height('100%')
          .aspectRatio(this.videoRatio === null ? null : this.videoRatio)
          .onLoad(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              this.videoXComponentId
            )
            this.sdk.linkmicManager.setupVideoRender(renderParam)
          })
          .onDestroy(() => {
            const renderParam = new PLVLinkMicVideoRenderParam(
              this.viewer.linkmicId,
              this.videoXComponentId
            )
            this.sdk.linkmicManager.removeVideoRender(renderParam)
          })
      } else {
        // 未开启摄像头占位图
        Stack() {
          Image($r('app.media.plvsa_linkmic_video_disabled_placeholder'))
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

      if (this.viewerInfoOverlayVisible) {
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

          Row({ space: 6 }) {
            // 观众参与连麦计时
            if (!this.viewer.isMyself && this.sdk.channelData.viewerType === PLVUserType.USERTYPE_TEACHER) {
              PLVSALinkMicViewerTimerLayout({
                viewer: this.viewer
              })
            }
            // 嘉宾 连麦状态
            if (this.viewer.isMyself && this.viewer.viewerType === PLVUserType.USERTYPE_GUEST) {
              Text(this.guestLinkmicStateJoined ? $r('app.string.plvsa_linkmic_guest_state_joined') : $r('app.string.plvsa_linkmic_guest_state_not_joined'))
                .id('linkmic_item_guest_state_text')
                .fontColor('#F0F1F5')
                .fontSize(11)
                .padding({
                  top: 2,
                  bottom: 2,
                  left: 4,
                  right: 4
                })
                .borderRadius(8)
                .backgroundColor(this.guestLinkmicStateJoined ? '#CC09C5B3' : '#CCF1453D')
            }
            // 主讲图标
            if (this.speakerIconVisible) {
              Image($r('app.media.plvsa_linkmic_item_speaker_icon'))
                .width(16)
                .height(16)
            }
          }
          .id('linkmic_item_top_left_corner_row')
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top }
          })
          .margin({
            top: 2,
            left: 2
          })

        }
      }
    }
    .width('100%')
    .height('100%')
    .onClick(() => this.onClickItemView())
  }

  private audioVolumeIcon(): Resource {
    if (!this.isAudioEnable) {
      return $r('app.media.plvsa_linkmic_audio_volume_closed')
    } else {
      const clampValue = extendNumber(this.audioVolume).coerceIn_ext(0, 100)
      const normalizeVolume = Math.round(clampValue / 10) * 10
      return $r(`app.media.plvsa_linkmic_audio_volume_value_${normalizeVolume}`)
    }
  }

  private onClickItemView() {
    const networkDisconnected = this.pageDataBus.networkDisconnectedMaskVisible.value ?? false
    if (networkDisconnected) {
      return
    }
    this.tapCount++
    if (this.tapCountTimeout === undefined) {
      setTimeout(() => {
        if (this.tapCount === 1) {
          this.customOnClickItemOnce()
        } else if (this.tapCount >= 2) {
          this.customOnClickItemOnce()
        }
        this.tapCount = 0
        this.tapCountTimeout = undefined
      }, 200)
    }
    if (this.tapCount >= 2) {
      clearTimeout(this.tapCountTimeout)
      this.customOnClickItemTwice()
      this.tapCount = 0
      this.tapCountTimeout = undefined
    }
  }

  private onClickItemViewOnce() {
    if (this.memberControlDialogSwitcher?.canShowMemberControlDialog !== true) {
      return
    }
    this.linkmicMemberControlDialogController = new CustomDialogController({
      builder: PLVSALinkMicMemberControlDialog({
        viewer: this.viewer
      }),
      alignment: DialogAlignment.BottomEnd,
      customStyle: true
    })
    this.linkmicMemberControlDialogController.open()
  }

  private onClickItemViewTwice() {
    this.pageDataBus.linkmicFullScreenViewer.setValue(this.viewer)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

// </editor-fold>

// <editor-fold defaultstate="collapsed" desc="Background Task">

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

// </editor-fold>

export enum PLVSALinkMicLayoutType {
  /**
   * 平铺
   */
  TILE = 2,
  /**
   * 主讲
   */
  SPEAKER = 3
}