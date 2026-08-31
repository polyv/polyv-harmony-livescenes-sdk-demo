import { PLVCommonConstants, PLVLiveSceneSDK, PLVNodeController } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, PLVMediaOutputMode, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { PLVLWMarqueeLayout } from '../marquee/PLVLWMarqueeLayout';
import { PLVLWWatermarkLayout } from '../watermark/PLVLWWatermarkLayout';
import { PLVLWPiPManager } from '../../../common/PLVLWPiPManager';

@Component
export struct PLVLWPlayerView {
  @State viewData: PlayerViewData = lateInit()
  @State private isAudioMode: boolean = false
  @State private isPPTToMainScreen: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observePlayerViewState()
  }

  build() {
    Stack() {
      XComponent({
        id: `plvlw_video_xcomponent`,
        type: "surface",
        libraryname: "plvplayer_xcomponent",
        controller: PLVLWPiPManager.instance.xComponentController
      }) {
      }
      .onLoad((component) => {
        if (PLVLWPiPManager.instance.consumeRestoringPlayer(this.viewData.sdk.uniqueId)) {
          this.viewData.sdk.playerManager.attachMainMediaPlayerWithComponent(component!)
        } else {
          this.viewData.sdk?.playerManager.startMainMediaPlayerWithComponent(component!)
        }
        this.onPreviousData()
        PLVLWPiPManager.instance.onXComponentReady()
      })
      .onDestroy(() => {
        if (!PLVLWPiPManager.instance.shouldKeepPlayerAlive(this.viewData.sdk.uniqueId)) {
          this.viewData.sdk?.playerManager.release()
        }
      })
      .id('plvlw_player_xcomponent')
      .width(PLVCommonConstants.FULL_PERCENT)
      .height(PLVCommonConstants.FULL_PERCENT)

      PLVLWMarqueeLayout({
        sdk: this.viewData.sdk
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

      PLVLWWatermarkLayout({
        sdk: this.viewData.sdk
      })
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)

      if (this.isPPTToMainScreen && this.isAudioMode) {
        Column() {
          Image($r('app.media.plvlw_bg_player_audio_mode'))
            .width('60%')
            .aspectRatio(560 / 444)
            .objectFit(ImageFit.Contain)
        }
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#1B202D')
        .hitTestBehavior(HitTestMode.None)
      }
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  onPreviousData() {
    const previousManager = this.viewData.sdk?.previousManager
    previousManager?.selPreviousDataPromise.observe((selData) => {
      this.viewData.sdk?.playerManager.changePlaybackVid(selData?.videoPoolId)
    })
    previousManager?.selChapterDataPromise.observe((selData) => {
      if (selData.isPostChanged) {
        this.viewData.sdk?.playerManager.mainMediaPlayer.seek(selData?.timeMillisecond)
      }
    })
  }

  observePlayerViewState() {
    watchStates(() => {
      const outputMode = this.viewData.sdk?.playerManager.mainMediaPlayer.getBusinessListenerRegistry()
        .currentMediaOutputMode
        .value ?? PLVMediaOutputMode.AUDIO_VIDEO
      this.isAudioMode = outputMode === PLVMediaOutputMode.AUDIO_ONLY
      this.isPPTToMainScreen = this.viewData.layoutDataBus?.isPPTToMainScreen.value ?? false
    }).pushTo(this.observers)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
    this.observers = []
  }
}

export class PlayerViewData {
  sdk: PLVLiveSceneSDK
  layoutDataBus?: PLVLWLayoutDataBus

  constructor(sdk: PLVLiveSceneSDK, layoutDataBus?: PLVLWLayoutDataBus) {
    this.sdk = sdk
    this.layoutDataBus = layoutDataBus
  }
}

@Builder
export function playerViewBuilder(data: PlayerViewData) {
  PLVLWPlayerView({ viewData: data })
}

export function createPlayerViewNodeController(isShow: boolean, data: PlayerViewData): PLVNodeController {
  return new PLVNodeController({
    name: 'playerViewNodeController_' + data.sdk.uniqueId,
    isShow: isShow,
    wrapBuilder: wrapBuilder(playerViewBuilder),
    params: data
  })
}
