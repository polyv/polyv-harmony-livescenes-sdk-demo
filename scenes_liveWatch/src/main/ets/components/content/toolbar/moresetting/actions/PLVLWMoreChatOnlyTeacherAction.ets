import { MutableObserver, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../../../common/PLVLWLayoutDataBus';
import { MoreSettingActionCallback, MoreSettingActionView } from './more-setting-action-common';

@Component
export struct PLVLWMoreChatOnlyTeacherAction {
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @Consume('moreSettingActionCallback') moreSettingActionCallback: MoreSettingActionCallback
  @State private isSelect: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    watchStates(() => {
      this.isSelect = this.layoutDataBus.chatTabStatus.value?.messageShowType === 'only_teacher'
    }).pushTo(this.observers)
  }

  build() {
    MoreSettingActionView({
      icon: this.isSelect ? $r('app.media.plvlw_more_chat_only_teacher_icon_selected') : $r('app.media.plvlw_more_chat_only_teacher_icon_not_selected'),
      title: $r('app.string.plvlw_chatroom_show_only_teacher_message')
    }).onClick(() => {
      this.layoutDataBus.chatTabStatus.mutate({
        messageShowType: this.isSelect ? 'all' : 'only_teacher'
      })
      this.moreSettingActionCallback.hideMoreSettingDialog?.()
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}