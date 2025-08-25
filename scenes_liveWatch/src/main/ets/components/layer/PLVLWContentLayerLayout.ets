import {
  PLVAvoidAreaChangeListener,
  PLVChannelData,
  PLVCommonConstants,
  PLVDeviceUtils,
  PLVLiveScene,
  PLVLiveSceneSDK,
  PLVMediaQueryListener,
  PLVUtils
} from '@polyvharmony/live-scenes-sdk';
import { Rect } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../common/PLVLWLayoutDataBus';
import { PLVLWInteractTopBarLayout } from '../content/interacttopbar/PLVLWInteractTopBarLayout';
import { PLVLWTabContentLayout } from '../content/tabcontent/PLVLWTabContentLayout';
import { PLVLWToolBarLayout } from '../content/toolbar/PLVLWToolBarLayout';
import { PLVLWWatchInfoLayout } from '../content/watchinfo/PLVLWWatchInfoLayout';
import { PLVLWContentLayoutEmbedPlayerController } from '../player/controller/PLVLWPlayerControllerLayout';

@Preview
@Component
export struct PLVLWContentLayerLayout {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @LocalStorageLink('channelData') channelData?: PLVChannelData = undefined
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  private liveScene?: PLVLiveScene = this.channelData?.liveScene
  private orientationListener: PLVMediaQueryListener | undefined
  private avoidAreaChangeListener: PLVAvoidAreaChangeListener | undefined
  @State isPortrait: boolean = true
  @State topPadding: number = PLVDeviceUtils.getStatusBarHeight()
  @State bottomPadding: number = 6 + PLVDeviceUtils.getNavigationIndicatorHeight()

  override aboutToAppear(): void {
    this.orientationListener = PLVUtils.listenerOrientation((result) => {
      this.isPortrait = !result.matches
      this.topPadding = !this.isPortrait ? 0 : PLVDeviceUtils.getStatusBarHeight()
    })
    this.avoidAreaChangeListener = PLVUtils.listenerAvoidAreaChange(() => {
      this.topPadding = !this.isPortrait ? 0 : PLVDeviceUtils.getStatusBarHeight()
    })
  }

  aboutToDisappear(): void {
    this.orientationListener?.off()
    this.avoidAreaChangeListener?.off()
  }

  build() {
    Stack() {
      Tabs({ index: 0 }) {
        TabContent() {
          RelativeContainer() {
            // 观看信息区域
            PLVLWWatchInfoLayout()
              .alignRules({
                top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
                left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start }
              })
              .id('watchInfoLayout')

            // 互动顶部栏
            PLVLWInteractTopBarLayout()
              .alignRules({
                top: { anchor: 'watchInfoLayout', align: VerticalAlign.Bottom },
              })
              .id('interactTopBarLayout')

            // 播放器区域占位
            Stack()
              .id('plvlw_player_anchor_space')
              .width(PLVCommonConstants.FULL_PERCENT)
              .aspectRatio(16 / 9)
              .alignRules({
                top: { anchor: 'interactTopBarLayout', align: VerticalAlign.Bottom }
              })
              .onAreaChange((oldArea, newArea) => {
                this.postPlayerLocationUpdate(newArea)
              })

            // 功能菜单区域
            PLVLWTabContentLayout()
              .alignRules({
                top: { anchor: 'plvlw_player_anchor_space', align: VerticalAlign.Bottom },
                left: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.Start },
                bottom: { anchor: 'plvlw_content_layout_embed_player_controller', align: VerticalAlign.Top }
              })
              .id('tabContentLayout')
              .margin({
                bottom: 8
              })

            // 播放器控制（竖屏全屏）
            PLVLWContentLayoutEmbedPlayerController()
              .id('plvlw_content_layout_embed_player_controller')
              .width(PLVCommonConstants.FULL_PERCENT)
              .alignRules({
                bottom: { anchor: 'plvlw_tool_bar_layout', align: VerticalAlign.Top }
              })

            // 底部按钮
            PLVLWToolBarLayout()
              .id('plvlw_tool_bar_layout')
              .alignRules({
                bottom: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Bottom }
              })
              .visibility(this.isPortrait ? Visibility.Visible : Visibility.None)
          }
        }

        if (PLVLiveScene.PORTRAIT_TEMPLATE == this.liveScene) {
          TabContent() {
          }
        }
      }
      .barHeight(0)
      .scrollable(PLVLiveScene.PORTRAIT_TEMPLATE == this.liveScene)
      .padding({ top: this.topPadding, bottom: this.bottomPadding })
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)
      .hitTestBehavior(HitTestMode.Transparent)
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer, others: Array<GestureRecognizer>): GestureJudgeResult => {
        if (event.fingerList.length == 1) {
          const finger = event.fingerList[0]
          if ((this.layoutDataBus.bottomLayerViewTouchArea.value ?? new Rect()).contains(finger.globalX, finger.globalY)) {
            return GestureJudgeResult.REJECT;
          }
        }
        return GestureJudgeResult.CONTINUE;
      }, true)
      .gesture(SwipeGesture())
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  private postPlayerLocationUpdate(anchorArea: Area) {
    const rect = new Rect({
      left: anchorArea.globalPosition.x as number,
      top: anchorArea.globalPosition.y as number,
      right: (anchorArea.globalPosition.x as number) + (anchorArea.width as number),
      bottom: (anchorArea.globalPosition.y as number) + (anchorArea.height as number),
    })
    this.layoutDataBus.playerLocation.setValue(rect)
  }

}