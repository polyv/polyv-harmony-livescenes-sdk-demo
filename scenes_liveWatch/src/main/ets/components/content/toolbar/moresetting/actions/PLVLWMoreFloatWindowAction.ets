import { MutableObserver } from '@polyvharmony/media-player-sdk'
import { PLVLWPiPManager } from '../../../../../common/PLVLWPiPManager'
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common'

@Component
export struct PLVLWMoreFloatWindowAction {
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    PLVLWPiPManager.instance.canShowPiPAction
      .observe((canShow: boolean) => this.isVisible = canShow)
      .pushTo(this.observers)
  }

  build() {
    MoreSettingActionView({
      icon: $r('app.media.plvlw_more_float_window_icon'),
      title: $r('app.string.plvlw_player_float_window')
    })
      .onClick(() => {
        this.moreSettingActionCallback.hideMoreSettingDialog?.()
        PLVLWPiPManager.instance.startPiPAndLeave()
      })
      .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}
