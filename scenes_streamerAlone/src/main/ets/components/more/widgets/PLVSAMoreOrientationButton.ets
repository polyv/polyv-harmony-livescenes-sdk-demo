import { PLVLiveSceneSDK, PLVPushOrientation } from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { common } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { PLVSAPageDataBus } from '../../../common/PLVSAPageDataBus';

@Component
export struct PLVSAMoreOrientationButton {
  iconPadding: number = 8
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('pageDataBus') pageDataBus: PLVSAPageDataBus
  private context = getContext() as common.UIAbilityContext

  aboutToAppear(): void {

  }

  build() {
    Column() {
      Image($r('app.media.plvsa_more_orientation_icon'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_more_orientation'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(async () => {
      const orientation = display.getDefaultDisplaySync().orientation
      const isPortrait = orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED
      const nextIsPortrait = !isPortrait
      const nextWindowOrientation = nextIsPortrait ? window.Orientation.PORTRAIT : window.Orientation.LANDSCAPE
      const nextPushOrientation = nextIsPortrait ? PLVPushOrientation.PORTRAIT : PLVPushOrientation.LANDSCAPE
      const windowInstance = await window.getLastWindow(this.context)
      windowInstance.setPreferredOrientation(nextWindowOrientation)
      this.sdk.streamerManager.setPushOrientation(nextPushOrientation)
      this.pageDataBus.recoverSetting.update({
        isPortrait: nextIsPortrait
      })
    })
  }

  aboutToDisappear(): void {

  }
}