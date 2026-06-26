import { PLVLiveSceneSDK, PLVLoginType } from '@polyvharmony/live-scenes-sdk'
import { lateInit } from '@polyvharmony/media-player-sdk'
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common'

@Component
export struct PLVLWMoreShowAnnouncementAction {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback

  build() {
    if (this.sdk.channelData.loginType === PLVLoginType.LIVE) {
      MoreSettingActionView({
        icon: $r('app.media.plvlw_more_show_announcement_icon'),
        title: $r('app.string.plvlw_live_bulletin')
      }).onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        this.sdk.interactManager.showBulletin()
      })
    }
  }
}