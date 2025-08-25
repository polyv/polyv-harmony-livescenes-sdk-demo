import { PLVCommonConstants, PLVLiveSceneSDK, PLVNodeController } from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';

@Component
export struct PLVLWPlayerView {
  @State viewData: PlayerViewData = lateInit()

  build() {
    XComponent({
      id: `plvlw_video_xcomponent`,
      type: "surface",
      libraryname: "plvplayer_xcomponent"
    }) {
    }
    .onLoad((component) => {
      this.viewData.sdk?.playerManager.startMainMediaPlayerWithComponent(component!)
      this.onPreviousData()
    })
    .onDestroy(() => {
      this.viewData.sdk?.playerManager.release()
    })
    .id('plvlw_player_xcomponent')
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