import { PLVCallback, PLVLiveSceneSDK } from "@polyvharmony/live-scenes-sdk";
import { lateInit } from "@polyvharmony/media-player-sdk";

@Component
export struct PLVSAMoreSignInButton {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  iconPadding: number = 8
  onClicked: PLVCallback | undefined

  build() {
    Column() {
      Image($r('app.media.plvsa_more_interact_signin'))
        .width(48)
        .height(48)
        .padding(this.iconPadding)
        .objectFit(ImageFit.Contain)
      Text($r('app.string.plvsa_interact_sign_in'))
        .fontColor("#FFFFFF")
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .onClick(() => {
      this.onClicked?.()
      this.sdk.streamerInteractManager.showSignIn()
    })
  }
}