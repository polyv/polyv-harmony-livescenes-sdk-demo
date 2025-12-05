import { PLVCommonConstants, PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';
import { PLVLWCastController } from './variant/PLVLWCastController';
import { PLVLWPlayerControllerLiveLandLocked } from './variant/PLVLWPlayerControllerLiveLandLocked';
import { PLVLWPlayerControllerLiveLandscape } from './variant/PLVLWPlayerControllerLiveLandscape';
import { PLVLWPlayerControllerLivePortFullScreen } from './variant/PLVLWPlayerControllerLivePortFullScreen';
import { PLVLWPlayerControllerLivePortHalfScreen } from './variant/PLVLWPlayerControllerLivePortHalfScreen';
import { PLVLWPlayerControllerPlaybackLandLocked } from './variant/PLVLWPlayerControllerPlaybackLandLocked';
import { PLVLWPlayerControllerPlaybackLandscape } from './variant/PLVLWPlayerControllerPlaybackLandscape';
import { PLVLWPlayerControllerPlaybackPortFullScreen } from './variant/PLVLWPlayerControllerPlaybackPortFullScreen';
import { PLVLWPlayerControllerPlaybackPortHalfScreen } from './variant/PLVLWPlayerControllerPlaybackPortHalfScreen';
import { PLVLWPlayerControllerVariantState } from './vo/PLVLWPlayerControllerVariantState';
import { PLVLWCastControlHandler } from './widget/PLVLWCastControlHandler';
import { PLVLWPlayerControllerGestureHandler } from './widget/PLVLWPlayerControllerGestureHandler';

@Component
export struct PLVLWPlayerControllerLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private variantState: PLVLWPlayerControllerVariantState = new PLVLWPlayerControllerVariantState()
  @State private isVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const variantState = new PLVLWPlayerControllerVariantState()
      variantState.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      variantState.isPlayerFullscreen = this.layoutDataBus.playerFullscreen.value ?? false
      variantState.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
      variantState.isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
      variantState.isCasting = this.layoutDataBus.mediaCast.isCasting.value ?? false
      this.variantState = variantState
      this.isVisible = this.layoutDataBus.playerControllerStatus.value?.visible ?? false
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      PLVLWPlayerControllerGestureHandler()
      PLVLWCastControlHandler()

      Stack() {
        if (PLVLWPlayerControllerLivePortHalfScreen.match(this.variantState)) {
          PLVLWPlayerControllerLivePortHalfScreen()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWPlayerControllerLivePortFullScreen.match(this.variantState)) {
          PLVLWPlayerControllerLivePortFullScreen()
        }
        if (PLVLWPlayerControllerLiveLandLocked.match(this.variantState)) {
          PLVLWPlayerControllerLiveLandLocked()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWPlayerControllerLiveLandscape.match(this.variantState)) {
          PLVLWPlayerControllerLiveLandscape()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWPlayerControllerPlaybackPortHalfScreen.match(this.variantState)) {
          PLVLWPlayerControllerPlaybackPortHalfScreen()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWPlayerControllerPlaybackLandLocked.match(this.variantState)) {
          PLVLWPlayerControllerPlaybackLandLocked()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWPlayerControllerPlaybackLandscape.match(this.variantState)) {
          PLVLWPlayerControllerPlaybackLandscape()
            .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
        }
        if (PLVLWCastController.match(this.variantState)) {
          PLVLWCastController()
        }
      }
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

@Component
export struct PLVLWContentLayoutEmbedPlayerController {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private variantState: PLVLWPlayerControllerVariantState = new PLVLWPlayerControllerVariantState()

  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      const variantState = new PLVLWPlayerControllerVariantState()
      variantState.isPortrait = this.layoutDataBus.isPortrait.value ?? true
      variantState.isPlayerFullscreen = this.layoutDataBus.playerFullscreen.value ?? false
      variantState.isLive = this.sdk.channelData.loginType === PLVLoginType.LIVE
      variantState.isLocked = this.layoutDataBus.playerControllerStatus.value?.locked ?? false
      variantState.isCasting = this.layoutDataBus.mediaCast.isCasting.value ?? false
      this.variantState = variantState
    }).pushTo(this.observers)
  }

  build() {
    if (PLVLWPlayerControllerPlaybackPortFullScreen.match(this.variantState)) {
      PLVLWPlayerControllerPlaybackPortFullScreen()
    }
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}