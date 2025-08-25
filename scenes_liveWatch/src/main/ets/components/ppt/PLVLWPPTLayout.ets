import { PLVChannelData, PLVCommonConstants, PLVLiveChannelType, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, PLVLiveStatusEnum, PLVMediaPlayerState, Rect, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWPlayerControllerPlayPauseButton } from '../player/controller/widget/PLVLWPlayerControllerPlayPauseButton';
import { PLVLWPPTPlayerExchangeView } from './node/PLVLWPPTPlayerExchangeView';
import { FLOATING_WINDOW_INIT_POSITION_PADDING, FLOATING_WINDOW_INIT_POSITION_TOP, PLVLWFloatWindowView } from './widget/PLVLWFloatWindowView';

const FLOATING_WINDOW_LAND_VIDEO_PORT_WIDTH = 176 // 横向视频，竖向屏幕
const FLOATING_WINDOW_LAND_VIDEO_PORT_HEIGHT = 100 // 横向视频，竖向屏幕
const FLOATING_WINDOW_LAND_VIDEO_LAND_WIDTH = 202 // 横向视频，横向屏幕
const FLOATING_WINDOW_LAND_VIDEO_LAND_HEIGHT = 114 // 横向视频，横向屏幕
const FLOATING_WINDOW_PORT_VIDEO_PORT_WIDTH = 90 // 竖向视频，竖向屏幕
const FLOATING_WINDOW_PORT_VIDEO_PORT_HEIGHT = 120 // 竖向视频，竖向屏幕
const FLOATING_WINDOW_PORT_VIDEO_LAND_WIDTH = 102 // 竖向视频，横向屏幕
const FLOATING_WINDOW_PORT_VIDEO_LAND_HEIGHT = 136 // 竖向视频，横向屏幕
const FLOATING_WINDOW_PACK_UP_WIDTH = 18 // 缩小窗口按钮宽度

@Preview
@Component
export struct PLVLWPPTLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State floatingWindowVisibility: Visibility = Visibility.Visible
  @State lastFloatingWindowVisibility: Visibility = Visibility.Visible
  @State edges: Edges = { top: FLOATING_WINDOW_INIT_POSITION_TOP, right: FLOATING_WINDOW_INIT_POSITION_PADDING }
  @State floatingWindowWidth: number = FLOATING_WINDOW_LAND_VIDEO_PORT_WIDTH
  @State floatingWindowHeight: number = FLOATING_WINDOW_LAND_VIDEO_PORT_HEIGHT
  @State containerWidth: number = 0
  @State containerHeight: number = 0
  @State @Watch('onFloatingWindowPackUp') isFloatingWindowPackUp: boolean = false
  @State packUpFloatingWindowVisibility: Visibility = Visibility.None
  @State packUpFloatingWindowWidth: number = FLOATING_WINDOW_PACK_UP_WIDTH
  @State isPPTToMainScreen: boolean = false
  @State isShowFloatingController: boolean = false
  @State floatingWindowAspectRatio: number = -1
  @State videoSize?: Rect = undefined
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.onPlayerData()
    this.onLayoutData()
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }

  build() {
    Stack() {
      if (PLVLiveChannelType.PPT === this.channelData?.channelType) {
        PLVLWFloatWindowView({
          edges: this.edges,
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight,
          floatingWindowVisibility: this.floatingWindowVisibility,
          floatingWindowWidth: this.floatingWindowWidth,
          floatingWindowHeight: this.floatingWindowHeight,
          floatingWindowAspectRatio: this.floatingWindowAspectRatio,
          contentBuilder: this.floatingContentView,
          onClickEvent: () => {
            this.isShowFloatingController = !this.isShowFloatingController
          },
          onAreaChangeEvent: (newValue) => {
            setTimeout(() => {
              this.layoutDataBus.topLayerViewTouchArea.setValue(newValue)
            }, this.floatingWindowVisibility === Visibility.Visible ? 20 : 0) // 让可见的浮窗最后触发
          }
        })
        PLVLWFloatWindowView({
          edges: this.edges,
          containerWidth: this.containerWidth,
          containerHeight: this.containerHeight,
          floatingWindowVisibility: this.packUpFloatingWindowVisibility,
          floatingWindowWidth: this.packUpFloatingWindowWidth,
          floatingWindowHeight: this.floatingWindowHeight,
          contentBuilder: this.packUpFloatingContentView,
          floatingWindowBorderRadius: { topLeft: 8, bottomLeft: 8 },
          enableHorizontalMove: false,
          onAreaChangeEvent: (newValue) => {
            setTimeout(() => {
              this.layoutDataBus.topLayerViewTouchArea.setValue(newValue)
            }, this.packUpFloatingWindowVisibility === Visibility.Visible ? 20 : 0)
          }
        })
      }
    }
    .hitTestBehavior(HitTestMode.None)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .onAreaChange((oldValue: Area, newValue: Area) => {
      if (oldValue.width !== newValue.width) {
        this.containerWidth = newValue.width as number
      }
      if (oldValue.height !== newValue.height) {
        this.containerHeight = newValue.height as number
      }
    })
  }

  @LocalBuilder
  floatingContentView() {
    RelativeContainer() {
      PLVLWPPTPlayerExchangeView({ isMainScreenUse: false })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
      if (this.isShowFloatingController) {
        Image($r('app.media.plvlw_ppt_floating_pack_up'))
          .alignRules({
            top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .width(24)
          .height(24)
          .padding(4)
          .margin({ top: 4, right: 4 })
          .onClick(() => {
            this.isFloatingWindowPackUp = true
          })
        PLVLWPlayerControllerPlayPauseButton()
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })
          .width(24)
          .height(24)
          .padding(2)
          .visibility(this.isPPTToMainScreen ? Visibility.Visible : Visibility.Hidden)
          .margin({ left: 2, bottom: 2 })
        Image($r('app.media.plvlw_ppt_floating_exchange'))
          .alignRules({
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom },
            right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
          })
          .width(24)
          .height(24)
          .padding(2)
          .margin({ right: 4, bottom: 2 })
          .onClick(() => {
            this.layoutDataBus.isPPTToMainScreen.setValue(!this.layoutDataBus.isPPTToMainScreen.value)
          })
      } else {
        if (this.channelData?.loginType === PLVLoginType.LIVE) {
          Text() {
            ImageSpan($r('app.media.plvlw_player_mic_icon'))
              .width(16)
              .height(16)
              .margin({ right: 4 })
            Span($r('app.string.plvlw_player_lecturer'))
          }
          .alignRules({
            left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
            bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
          })
          .fontColor($r('app.color.plvlw_neutral_dark_white'))
          .fontSize(12)
          .margin({ left: 4, bottom: 4 })
        }
      }
    }
    .hitTestBehavior(HitTestMode.None)
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor($r('app.color.plvlw_neutral_light_black'))
  }

  @LocalBuilder
  packUpFloatingContentView() {
    Image($r('app.media.plvlw_ppt_floating_back'))
      .objectFit(ImageFit.Contain)
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .backgroundColor($r('app.color.plvlw_neutral_dark_white_40'))
      .onClick(() => {
        this.isFloatingWindowPackUp = false
      })
  }

  onFloatingWindowPackUp() {
    this.floatingWindowVisibility = this.isFloatingWindowPackUp ? Visibility.None : this.lastFloatingWindowVisibility
    this.packUpFloatingWindowVisibility = this.isFloatingWindowPackUp ? Visibility.Visible : Visibility.None
    this.edges.right = 0
  }

  onPlayerData() {
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value ?? true
      const videoSize = this.sdk.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .videoSize
        .value ?? new Rect()
      this.videoSize = videoSize
      const isPortraitVideo = videoSize.height() > videoSize.width()
      if (isPortrait) {
        this.floatingWindowWidth = isPortraitVideo ? FLOATING_WINDOW_PORT_VIDEO_PORT_WIDTH : FLOATING_WINDOW_LAND_VIDEO_PORT_WIDTH
        this.floatingWindowHeight = isPortraitVideo ? FLOATING_WINDOW_PORT_VIDEO_PORT_HEIGHT : FLOATING_WINDOW_LAND_VIDEO_PORT_HEIGHT
      } else {
        this.floatingWindowWidth = isPortraitVideo ? FLOATING_WINDOW_PORT_VIDEO_LAND_WIDTH : FLOATING_WINDOW_LAND_VIDEO_LAND_WIDTH
        this.floatingWindowHeight = isPortraitVideo ? FLOATING_WINDOW_PORT_VIDEO_LAND_HEIGHT : FLOATING_WINDOW_LAND_VIDEO_LAND_HEIGHT
      }
      this.updateFloatingWindowRatio()
    }).pushTo(this.observers)
    watchStates(() => {
      const liveStatus = this.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
        .liveStatus
        .value
      const playerStatus = this.sdk?.playerManager.mainMediaPlayer.getStateListenerRegistry()
        .playerState
        .value
      const playerStatusVisible = playerStatus !== PLVMediaPlayerState.STATE_IDLE && playerStatus !== PLVMediaPlayerState.STATE_ERROR
      const playerStatusNone = !playerStatusVisible
      const liveStatusVisible = liveStatus === PLVLiveStatusEnum.LIVE
      const liveStatusNone = liveStatus === PLVLiveStatusEnum.PAUSE || liveStatus === PLVLiveStatusEnum.NO_LIVE
      // 按状态优先级判断
      if (liveStatusVisible) {
        this.updateFloatingWindowVisibility(Visibility.Visible)
      } else if (liveStatusNone) {
        this.updateFloatingWindowVisibility(Visibility.None)
      } else if (playerStatusVisible) {
        this.updateFloatingWindowVisibility(Visibility.Visible)
      } else if (playerStatusNone) {
        this.updateFloatingWindowVisibility(Visibility.None)
      }
    }).pushTo(this.observers)
  }

  onLayoutData() {
    watchStates(() => {
      this.isPPTToMainScreen = this.layoutDataBus.isPPTToMainScreen.value ?? false
      this.updateFloatingWindowRatio()
    }).pushTo(this.observers)
  }

  updateFloatingWindowVisibility(visibility: Visibility) {
    if (!this.isFloatingWindowPackUp) {
      this.floatingWindowVisibility = visibility
    }
    this.lastFloatingWindowVisibility = visibility
    if (visibility === Visibility.None) {
      this.isFloatingWindowPackUp = false
      this.isShowFloatingController = false
    }
  }

  updateFloatingWindowRatio() {
    if (this.videoSize && this.isPPTToMainScreen) {
      const ratio = this.videoSize.width() / this.videoSize.height()
      this.floatingWindowAspectRatio = isNaN(ratio) || ratio == 0 ? -1 : ratio
    } else {
      this.floatingWindowAspectRatio = -1
    }
  }
}