import { FunctionBean as InteractFunctionBean, PLVLiveSceneSDK } from '@polyvharmony/live-scenes-sdk';
import { lateInit } from '@polyvharmony/media-player-sdk';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

const ICON_OVERRIDE_MAP = new Map<string, ResourceStr>()
ICON_OVERRIDE_MAP.set('SHOW_FEED_BACK', $r('app.media.plvlw_more_feed_back_icon'))

@Component
export struct PLVLWMoreInteractDynamicAction {
  interactAction: InteractFunctionBean = lateInit()
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isVisible: boolean = false
  @State private icon: ResourceStr | undefined = undefined
  @State private title: ResourceStr = $r('app.string.plvlw_interact_action_default_title')

  aboutToAppear(): void {
    this.isVisible = this.interactAction.isShow ?? false
    if (ICON_OVERRIDE_MAP.has(this.interactAction.event ?? '')) {
      this.icon = ICON_OVERRIDE_MAP.get(this.interactAction.event!)
    } else {
      this.icon = this.interactAction.icon ?? this.interactAction.iconUrl
    }
    this.title = this.interactAction.title ?? $r('app.string.plvlw_interact_action_default_title')
  }

  build() {
    MoreSettingActionView({
      icon: this.icon,
      title: this.title
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        if (this.interactAction.event) {
          this.sdk.interactManager.showDynamicAction(this.interactAction.event)
        }
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  aboutToDisappear(): void {
  }
}